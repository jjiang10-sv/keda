package main

import (
	"fmt"
	"time"
)

// you can also use imports, for example:
// import "fmt"
// import "os"

// you can write to stdout for debugging purposes, e.g.
// fmt.Println("this is a debug message")

func Solution(S string, T string) int {
	// Implement your solution here
	// Define the start and end times
	startTime, _ := time.Parse("15:04:05", "12:00:00")
	endTime, _ := time.Parse("15:04:05", "12:00:10") // Example range of 10 seconds

	// Loop from startTime to endTime, increasing by 1 second
	for t := startTime; t.Before(endTime) || t.Equal(endTime); t = t.Add(1 * time.Second) {
		fmt.Println(t.Format("15:04:05")) // Print the time in HH:MM:SS format
	}
	return 4
}
