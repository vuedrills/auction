package handlers

import (
	"net/http"

	"github.com/airmass/backend/pkg/storage"
	"github.com/gin-gonic/gin"
)

// UploadHandler handles file upload operations
type UploadHandler struct {
	storage *storage.SupabaseStorage
}

// NewUploadHandler creates a new upload handler
func NewUploadHandler(storage *storage.SupabaseStorage) *UploadHandler {
	return &UploadHandler{storage: storage}
}

// UploadImage handles single image upload
func (h *UploadHandler) UploadImage(c *gin.Context) {
	// Get the folder from query param (e.g., "auctions", "products", "avatars")
	folder := c.DefaultQuery("folder", "general")
	
	// Get the file from the request
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image file provided"})
		return
	}
	defer file.Close()

	// Validate file type
	contentType := header.Header.Get("Content-Type")
	allowedTypes := map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/webp": true,
		"image/gif":  true,
	}
	if !allowedTypes[contentType] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Allowed: jpg, png, webp, gif"})
		return
	}

	// Validate file size (max 10MB)
	if header.Size > 10*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File too large. Max size: 10MB"})
		return
	}

	// Upload to Supabase
	url, err := h.storage.UploadFile(file, header, folder)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"url":      url,
		"filename": header.Filename,
		"size":     header.Size,
	})
}

// UploadMultipleImages handles multiple image uploads
func (h *UploadHandler) UploadMultipleImages(c *gin.Context) {
	folder := c.DefaultQuery("folder", "general")
	
	// Parse multipart form with max 50MB total
	if err := c.Request.ParseMultipartForm(50 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
		return
	}

	files := c.Request.MultipartForm.File["images"]
	if len(files) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No images provided"})
		return
	}

	if len(files) > 10 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Maximum 10 images allowed"})
		return
	}

	allowedTypes := map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/webp": true,
		"image/gif":  true,
	}

	var urls []string
	var errors []string

	for _, header := range files {
		// Validate file type
		contentType := header.Header.Get("Content-Type")
		if !allowedTypes[contentType] {
			errors = append(errors, header.Filename+": invalid file type")
			continue
		}

		// Validate file size
		if header.Size > 10*1024*1024 {
			errors = append(errors, header.Filename+": file too large")
			continue
		}

		// Open file
		file, err := header.Open()
		if err != nil {
			errors = append(errors, header.Filename+": failed to open")
			continue
		}

		// Upload
		url, err := h.storage.UploadFile(file, header, folder)
		file.Close()
		
		if err != nil {
			errors = append(errors, header.Filename+": upload failed")
			continue
		}

		urls = append(urls, url)
	}

	c.JSON(http.StatusOK, gin.H{
		"urls":   urls,
		"errors": errors,
		"count":  len(urls),
	})
}
