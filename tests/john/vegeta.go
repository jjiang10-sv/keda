package main

// func main() {
// 	rate := vegeta.Rate{Freq: 100, Per: time.Second}
// 	duration := 10 * time.Second
// 	targeter := vegeta.NewStaticTargeter(vegeta.Target{
// 		Method: "GET",
// 		URL:    "http://localhost:8080/ping",
// 	})
// 	attacker := vegeta.NewAttacker()

// 	var metrics vegeta.Metrics
// 	for res := range attacker.Attack(targeter, rate, duration, "Big Bang!") {
// 		metrics.Add(res)
// 	}
// 	metrics.Close()
// 	printMetrics(&metrics)
// 	exportMetricsToJSON(&metrics)
// 	fmt.Printf("99th percentile: %s\n", metrics.Latencies.P99)
// }

// // printMetrics prints the basic metrics collected during the attack
// func printMetrics(metrics *vegeta.Metrics) {
// 	fmt.Printf("Requests per second: %.2f\n", metrics.Rate)
// 	fmt.Printf("Total requests: %d\n", metrics.Latencies.Total)
// 	fmt.Printf("Success rate: %.2f%%\n", metrics.Success*100/float64(metrics.Latencies.Total))
// 	fmt.Printf("Average latency: %.2f ms\n", metrics.Latencies.Mean.Seconds()*1000)

// 	// Print detailed latencies
// 	fmt.Println("Detailed latencies (ms):")
// 	fmt.Printf("P50: %.2f, P95: %.2f, P99: %.2f\n",
// 		metrics.Latencies.P50.Seconds()*1000,
// 		metrics.Latencies.P95.Seconds()*1000,
// 		metrics.Latencies.P99.Seconds()*1000)
// }

// // exportMetricsToJSON exports metrics to a JSON file for analysis
// func exportMetricsToJSON(metrics *vegeta.Metrics) {
// 	jsonMetrics, err := json.Marshal(metrics)
// 	if err != nil {
// 		log.Fatalf("Error serializing metrics to JSON: %v", err)
// 	}

// 	// Write to a file
// 	err = os.WriteFile("metrics.json", jsonMetrics, 0644)
// 	if err != nil {
// 		log.Fatalf("Error writing metrics to file: %v", err)
// 	}

// 	fmt.Println("Metrics have been exported to metrics.json.")
// }
