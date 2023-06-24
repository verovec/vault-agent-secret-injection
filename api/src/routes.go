package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func getPodInfo(c *gin.Context) {
	os_release, err_os_release := os.ReadFile("/etc/os-release")
	if err_os_release != nil {
		log.Println("Could not read os release file")
	}

	c.JSON(http.StatusOK, gin.H{
		"HOSTNAME":       os.Getenv("HOSTNAME"),
		"HOME":           os.Getenv("HOME"),
		"APP_ENV_SECRET": os.Getenv("APP_SECRET"),
		"APP_ENV_VALUE":  os.Getenv("APP_ENV"),
		"OS_RELEASE":     string(os_release),
	})
}
