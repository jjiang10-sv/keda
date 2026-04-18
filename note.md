
## builder.Builder
```go
type Builder = TypedBuilder[reconcile.Request]
type TypedBuilder[request comparable] struct {
	forInput         ForInput
	ownsInput        []OwnsInput
	rawSources       []source.TypedSource[request]
	watchesInput     []WatchesInput[request]
	mgr              manager.Manager
	globalPredicates []predicate.Predicate
	ctrl             controller.TypedController[request]
	ctrlOptions      controller.TypedOptions[request]
	name             string
	newController    func(name string, mgr manager.Manager, options controller.TypedOptions[request]) (controller.TypedController[request], error)
}
```
## controller.TypedController
```go
// TypedController implements an API.
type TypedController[request comparable] interface {
	// Reconciler is called to reconcile an object by Namespace/Name
	reconcile.TypedReconciler[request]

	// Watch watches the provided Source.
	Watch(src source.TypedSource[request]) error

	// Start starts the controller.  Start blocks until the context is closed or a
	// controller has an error starting.
	Start(ctx context.Context) error

	// GetLogger returns this controller logger prefilled with basic information.
	GetLogger() logr.Logger
}
```
## Internal Controller struct implement the interface of controller.TypedController.
```go
// Controller implements controller.Controller.
type Controller[request comparable] struct {
	// Name is used to uniquely identify a Controller in tracing, logging and monitoring.  Name is required.
	Name string

	// MaxConcurrentReconciles is the maximum number of concurrent Reconciles which can be run. Defaults to 1.
	MaxConcurrentReconciles int

	// Reconciler is a function that can be called at any time with the Name / Namespace of an object and
	// ensures that the state of the system matches the state specified in the object.
	// Defaults to the DefaultReconcileFunc.
	Do reconcile.TypedReconciler[request]

	// RateLimiter is used to limit how frequently requests may be queued into the work queue.
	RateLimiter workqueue.TypedRateLimiter[request]

	// NewQueue constructs the queue for this controller once the controller is ready to start.
	// This is a func because the standard Kubernetes work queues start themselves immediately, which
	// leads to goroutine leaks if something calls controller.New repeatedly.
	NewQueue func(controllerName string, rateLimiter workqueue.TypedRateLimiter[request]) workqueue.TypedRateLimitingInterface[request]

	// Queue is an listeningQueue that listens for events from Informers and adds object keys to
	// the Queue for processing
	Queue priorityqueue.PriorityQueue[request]

	// mu is used to synchronize Controller setup
	mu sync.Mutex

	// Started is true if the Controller has been Started
	Started bool

	// ctx is the context that was passed to Start() and used when starting watches.
	//
	// According to the docs, contexts should not be stored in a struct: https://golang.org/pkg/context,
	// while we usually always strive to follow best practices, we consider this a legacy case and it should
	// undergo a major refactoring and redesign to allow for context to not be stored in a struct.
	ctx context.Context

	// CacheSyncTimeout refers to the time limit set on waiting for cache to sync
	// Defaults to 2 minutes if not set.
	CacheSyncTimeout time.Duration

	// startWatches maintains a list of sources, handlers, and predicates to start when the controller is started.
	startWatches []source.TypedSource[request]

	// startedEventSourcesAndQueue is used to track if the event sources have been started.
	// It ensures that we append sources to c.startWatches only until we call Start() / Warmup()
	// It is true if startEventSourcesAndQueueLocked has been called at least once.
	startedEventSourcesAndQueue bool

	// didStartEventSourcesOnce is used to ensure that the event sources are only started once.
	didStartEventSourcesOnce sync.Once

	// LogConstructor is used to construct a logger to then log messages to users during reconciliation,
	// or for example when a watch is started.
	// Note: LogConstructor has to be able to handle nil requests as we are also using it
	// outside the context of a reconciliation.
	LogConstructor func(request *request) logr.Logger

	// RecoverPanic indicates whether the panic caused by reconcile should be recovered.
	// Defaults to true.
	RecoverPanic *bool

	// LeaderElected indicates whether the controller is leader elected or always running.
	LeaderElected *bool

	// EnableWarmup specifies whether the controller should start its sources when the manager is not
	// the leader. This is useful for cases where sources take a long time to start, as it allows
	// for the controller to warm up its caches even before it is elected as the leader. This
	// improves leadership failover time, as the caches will be prepopulated before the controller
	// transitions to be leader.
	//
	// Setting EnableWarmup to true and NeedLeaderElection to true means the controller will start its
	// sources without waiting to become leader.
	// Setting EnableWarmup to true and NeedLeaderElection to false is a no-op as controllers without
	// leader election do not wait on leader election to start their sources.
	// Defaults to false.
	EnableWarmup *bool

	ReconciliationTimeout time.Duration
}
```

### internal.Controller.startEventSourcesAndQueueLocked. It trigger source.Kind.Start()
```go
// startEventSourcesAndQueueLocked starts the queue and all event sources.
// It is called by Start() and Warmup() and ensures that the queue and event sources are only started once.
unc (c *Controller[request]) startEventSourcesAndQueueLocked(ctx context.Context) error {
	for _, watch := range c.startWatches {
        errGroup.Go(func() error {
            go func() {
                if err := watch.Start(ctx, c.Queue); err != nil {
                    return
                }
            }()
        })
    }
}

// Source.Kind is used to provide a source of events originating inside the cluster from Watches (e.g. Pod Create).
// Kind implements source.TypedSource[request] interface Start which add the eventHandler to the Kind.Type informer.
// the informer use client-go lister and reflector to watch the Kind.Type object.
type Kind[object client.Object, request comparable] struct {
	// Type is the type of object to watch.  e.g. &v1.Pod{}
	Type object

	// Cache used to watch APIs
	Cache cache.Cache

	Handler handler.TypedEventHandler[object, request]

	Predicates []predicate.TypedPredicate[object]

	// startedErr may contain an error if one was encountered during startup. If its closed and does not
	// contain an error, startup and syncing finished.
	startedErr  chan error
	startCancel func()
}


// Start is internal and should be called only by the Controller to register an EventHandler with the Informer
// to enqueue reconcile.Requests.
func (ks *Kind[object, request]) Start(ctx context.Context, queue workqueue.TypedRateLimitingInterface[request]) error {
	go func() {
		i, _ := ks.Cache.GetInformer(ctx, ks.Type)
		_, err := i.AddEventHandlerWithOptions(NewEventHandler(ctx, queue, ks.Handler, ks.Predicates), toolscache.HandlerOptions{
			Logger: &logKind,
		})
	}()
}
// source.NewEventHandler is used to create an event handler for the informer.

// EventHandler adapts a handler.EventHandler interface to a cache.ResourceEventHandler interface.
type EventHandler[object client.Object, request comparable] struct {
	// ctx stores the context that created the event handler
	// that is used to propagate cancellation signals to each handler function.
	ctx context.Context

	handler    handler.TypedEventHandler[object, request]
	queue      workqueue.TypedRateLimitingInterface[request]
	predicates []predicate.TypedPredicate[object]
}
// implement client-go cache ResourceEventHandler
type ResourceEventHandler interface {
	OnAdd(obj interface{}, isInInitialList bool)
	OnUpdate(oldObj, newObj interface{})
	OnDelete(obj interface{})
}
// eventHandler use predicates to filter out events and call the handler by pass the event and queue

// eventHandler and source.Kind object are initialized in the controller builder.doWatch(), then registered into the bulder.controller
var hdler handler.TypedEventHandler[client.Object, request]
reflect.ValueOf(&hdler).Elem().Set(reflect.ValueOf(&handler.EnqueueRequestForObject{}))
allPredicates := append([]predicate.Predicate(nil), blder.globalPredicates...)
allPredicates = append(allPredicates, blder.forInput.predicates...)
src := source.TypedKind(blder.mgr.GetCache(), obj, hdler, allPredicates...)
if err := blder.ctrl.Watch(src); err != nil 
```

## Conclusion
Now it is clear how k8s-operator works using control-runtime. 
1, operator ctrl.NewManager() -> create a manager
2, programer defines a reconcile struct and implement reconcile.Reconciler interface
3, register the controller into the manager by ctrl.NewControllerManagedBy(mgr).For(&kedav1alpha1.ScaledObject{}).Complete(r)
    3.1 NewControllerManagedBy() -> create a controller builder
    3.2 .For() -> set the object type to watch
    3.3 .Owns() -> set the owned object type to watch. for example HPA is owned by ScaledObject
    3.4 .Complete() -> calls doControler() and doWatch(). the builder will create a controller for the scaledObject and
    add it into manager as a runnable. then it create a event handler and ratelimit queue. the handler and queue is added into the scaledObject informer through a source.Kind when the controller started by the manager. the scaledObject informer and scaledObject controller share the same queue. 
4, operator calls manager.Start() -> start all runnables, including the scaledObject controller. the controller will then start its informer. the informer will watch the scaledObject events such as create,update and delete. when the informer detects an event, it will call the event handler, and the event handler will add the request into the queue. the controller will then process the request from the queue concurrently.

### Manager
```go

// Manager initializes shared dependencies such as Caches and Clients, and provides them to Runnables.
// A Manager is required to create Controllers.
type Manager interface {
	// Cluster holds a variety of methods to interact with a cluster.
	cluster.Cluster

	// Add will set requested dependencies on the component, and cause the component to be
	// started when Start is called.
	// Depending on if a Runnable implements LeaderElectionRunnable interface, a Runnable can be run in either
	// non-leaderelection mode (always running) or leader election mode (managed by leader election if enabled).
	Add(Runnable) error

	// Elected is closed when this manager is elected leader of a group of
	// managers, either because it won a leader election or because no leader
	// election was configured.
	Elected() <-chan struct{}

	// AddMetricsServerExtraHandler adds an extra handler served on path to the http server that serves metrics.
	// Might be useful to register some diagnostic endpoints e.g. pprof.
	//
	// Note that these endpoints are meant to be sensitive and shouldn't be exposed publicly.
	//
	// If the simple path -> handler mapping offered here is not enough,
	// a new http server/listener should be added as Runnable to the manager via Add method.
	AddMetricsServerExtraHandler(path string, handler http.Handler) error

	// AddHealthzCheck allows you to add Healthz checker
	AddHealthzCheck(name string, check healthz.Checker) error

	// AddReadyzCheck allows you to add Readyz checker
	AddReadyzCheck(name string, check healthz.Checker) error

	// Start starts all registered Controllers and blocks until the context is cancelled.
	// Returns an error if there is an error starting any controller.
	//
	// If LeaderElection is used, the binary must be exited immediately after this returns,
	// otherwise components that need leader election might continue to run after the leader
	// lock was lost.
	Start(ctx context.Context) error

	// GetWebhookServer returns a webhook.Server
	GetWebhookServer() webhook.Server

	// GetLogger returns this manager's logger.
	GetLogger() logr.Logger

	// GetControllerOptions returns controller global configuration options.
	GetControllerOptions() config.Controller
}


type controllerManager struct {
	sync.Mutex
	started bool

	stopProcedureEngaged *int64
	errChan              chan error
	runnables            *runnables

	// cluster holds a variety of methods to interact with a cluster. Required.
	cluster cluster.Cluster

	// recorderProvider is used to generate event recorders that will be injected into Controllers
	// (and EventHandlers, Sources and Predicates).
	recorderProvider *intrec.Provider

	// resourceLock forms the basis for leader election
	resourceLock resourcelock.Interface

	// leaderElectionReleaseOnCancel defines if the manager should step back from the leader lease
	// on shutdown
	leaderElectionReleaseOnCancel bool

	// metricsServer is used to serve prometheus metrics
	metricsServer metricsserver.Server

	// healthProbeListener is used to serve liveness probe
	healthProbeListener net.Listener

	// Readiness probe endpoint name
	readinessEndpointName string

	// Liveness probe endpoint name
	livenessEndpointName string

	// Readyz probe handler
	readyzHandler *healthz.Handler

	// Healthz probe handler
	healthzHandler *healthz.Handler

	// pprofListener is used to serve pprof
	pprofListener net.Listener

	// controllerConfig are the global controller options.
	controllerConfig config.Controller

	// Logger is the logger that should be used by this manager.
	// If none is set, it defaults to log.Log global logger.
	logger logr.Logger

	// leaderElectionStopped is an internal channel used to signal the stopping procedure that the
	// LeaderElection.Run(...) function has returned and the shutdown can proceed.
	leaderElectionStopped chan struct{}

	// leaderElectionCancel is used to cancel the leader election. It is distinct from internalStopper,
	// because for safety reasons we need to os.Exit() when we lose the leader election, meaning that
	// it must be deferred until after gracefulShutdown is done.
	leaderElectionCancel context.CancelFunc

	// elected is closed when this manager becomes the leader of a group of
	// managers, either because it won a leader election or because no leader
	// election was configured.
	elected chan struct{}

	webhookServer webhook.Server
	// webhookServerOnce will be called in GetWebhookServer() to optionally initialize
	// webhookServer if unset, and Add() it to controllerManager.
	webhookServerOnce sync.Once

	// leaderElectionID is the name of the resource that leader election
	// will use for holding the leader lock.
	leaderElectionID string
	// leaseDuration is the duration that non-leader candidates will
	// wait to force acquire leadership.
	leaseDuration time.Duration
	// renewDeadline is the duration that the acting controlplane will retry
	// refreshing leadership before giving up.
	renewDeadline time.Duration
	// retryPeriod is the duration the LeaderElector clients should wait
	// between tries of actions.
	retryPeriod time.Duration

	// gracefulShutdownTimeout is the duration given to runnable to stop
	// before the manager actually returns on stop.
	gracefulShutdownTimeout time.Duration

	// onStoppedLeading is callled when the leader election lease is lost.
	// It can be overridden for tests.
	onStoppedLeading func()

	// shutdownCtx is the context that can be used during shutdown. It will be cancelled
	// after the gracefulShutdownTimeout ended. It must not be accessed before internalStop
	// is closed because it will be nil.
	shutdownCtx context.Context

	internalCtx    context.Context
	internalCancel context.CancelFunc

	// internalProceduresStop channel is used internally to the manager when coordinating
	// the proper shutdown of servers. This channel is also used for dependency injection.
	internalProceduresStop chan struct{}
}
```
    
    
