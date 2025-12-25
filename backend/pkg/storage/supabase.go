package storage

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

// SupabaseStorage handles file uploads to Supabase Storage
type SupabaseStorage struct {
	url        string
	serviceKey string
	bucket     string
	httpClient *http.Client
}

// NewSupabaseStorage creates a new Supabase storage client
func NewSupabaseStorage(url, serviceKey, bucket string) *SupabaseStorage {
	return &SupabaseStorage{
		url:        url,
		serviceKey: serviceKey,
		bucket:     bucket,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}
}

// UploadFile uploads a file to Supabase Storage
func (s *SupabaseStorage) UploadFile(file multipart.File, header *multipart.FileHeader, folder string) (string, error) {
	// Generate unique filename
	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("%s/%s%s", folder, uuid.New().String(), ext)

	// Read file content
	content, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	// Upload to Supabase
	uploadURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", s.url, s.bucket, filename)

	req, err := http.NewRequest("POST", uploadURL, bytes.NewReader(content))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+s.serviceKey)
	req.Header.Set("Content-Type", header.Header.Get("Content-Type"))
	req.Header.Set("x-upsert", "true")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to upload: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("upload failed: %s - %s", resp.Status, string(body))
	}

	// Return public URL
	publicURL := fmt.Sprintf("%s/storage/v1/object/public/%s/%s", s.url, s.bucket, filename)
	return publicURL, nil
}

// UploadBytes uploads raw bytes to Supabase Storage
func (s *SupabaseStorage) UploadBytes(data []byte, filename, contentType, folder string) (string, error) {
	path := fmt.Sprintf("%s/%s", folder, filename)
	uploadURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", s.url, s.bucket, path)

	req, err := http.NewRequest("POST", uploadURL, bytes.NewReader(data))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+s.serviceKey)
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("x-upsert", "true")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to upload: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("upload failed: %s - %s", resp.Status, string(body))
	}

	publicURL := fmt.Sprintf("%s/storage/v1/object/public/%s/%s", s.url, s.bucket, path)
	return publicURL, nil
}

// UploadFromURL downloads image from URL and uploads to Supabase
func (s *SupabaseStorage) UploadFromURL(imageURL, folder string) (string, error) {
	// Download image
	resp, err := http.Get(imageURL)
	if err != nil {
		return "", fmt.Errorf("failed to download image: %w", err)
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read image: %w", err)
	}

	// Determine content type and extension
	contentType := resp.Header.Get("Content-Type")
	ext := ".jpg"
	if strings.Contains(contentType, "png") {
		ext = ".png"
	} else if strings.Contains(contentType, "webp") {
		ext = ".webp"
	}

	filename := uuid.New().String() + ext
	return s.UploadBytes(data, filename, contentType, folder)
}

// DeleteFile deletes a file from Supabase Storage
func (s *SupabaseStorage) DeleteFile(path string) error {
	deleteURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", s.url, s.bucket, path)

	req, err := http.NewRequest("DELETE", deleteURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+s.serviceKey)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to delete: %w", err)
	}
	defer resp.Body.Close()

	return nil
}

// ListFiles lists files in a folder
func (s *SupabaseStorage) ListFiles(folder string) ([]string, error) {
	listURL := fmt.Sprintf("%s/storage/v1/object/list/%s", s.url, s.bucket)

	body := map[string]interface{}{
		"prefix": folder,
	}
	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequest("POST", listURL, bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+s.serviceKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var files []struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&files); err != nil {
		return nil, err
	}

	var result []string
	for _, f := range files {
		result = append(result, f.Name)
	}
	return result, nil
}

// GetPublicURL returns the public URL for a file
func (s *SupabaseStorage) GetPublicURL(path string) string {
	return fmt.Sprintf("%s/storage/v1/object/public/%s/%s", s.url, s.bucket, path)
}
