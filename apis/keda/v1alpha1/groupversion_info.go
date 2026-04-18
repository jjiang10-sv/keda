/*
Copyright 2021 The KEDA Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Package v1alpha1 contains API Schema definitions for the keda v1alpha1 API group
// +kubebuilder:object:generate=true
// +groupName=keda.sh
package v1alpha1

import (
	"k8s.io/apimachinery/pkg/runtime/schema"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

var (
	// GroupVersion is group version used to register these objects
	GroupVersion = schema.GroupVersion{Group: "keda.sh", Version: "v1alpha1"}

	// SchemeGroupVersion is group version used to register these objects
	// added for generated clientset
	SchemeGroupVersion = GroupVersion
	//  Is it global or local? It is a package-level global variable. Because it is declared inside the var (...) block at the root level of
	// groupversion_info.go
	//  (and starts with an uppercase letter), it is globally accessible to every single file inside the v1alpha1 package, and even to other packages that import it (like main.go).
	// 2. Is it a pointer to the global builder that registers all types? Yes, exactly. It is a pointer (&) to a completely new scheme.Builder struct that is created specifically for this API group (keda.sh/v1alpha1).
	// Because SchemeBuilder is a global pointer, any other file inside the v1alpha1 folder (like scaledobject_types.go, scaledjob_types.go, etc.) can access it. During the Go initialization phase (init()), those other files all point to this exact same SchemeBuilder and use it to register their specific Go structs (using SchemeBuilder.Register())
	// Once all the files have finished registering their local types into this builder, the builder contains the complete list of all types for the v1alpha1 API, ready to be handed off to the main operator startup sequence!
	// SchemeBuilder is used to add go types to the GroupVersionKind scheme
	SchemeBuilder = &scheme.Builder{GroupVersion: GroupVersion}

	// AddToScheme adds the types in this group-version to the given scheme.
	AddToScheme = SchemeBuilder.AddToScheme
)

// Kind takes an unqualified kind and returns back a Group qualified GroupKind
// added for generated clientset
func Kind(kind string) schema.GroupKind {
	return GroupVersion.WithKind(kind).GroupKind()
}

// Resource takes an unqualified resource and returns a Group qualified GroupResource
// added for generated clientset
func Resource(resource string) schema.GroupResource {
	return GroupVersion.WithResource(resource).GroupResource()
}
