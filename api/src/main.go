package main

import (
	"github.com/gin-gonic/gin"
)

func mainRouter() *gin.Engine {
	router := gin.Default()
	router.GET("/", getPodInfo)
	return router
}

func main() {
	router := mainRouter()
	router.Run("0.0.0.0:8080")
}
