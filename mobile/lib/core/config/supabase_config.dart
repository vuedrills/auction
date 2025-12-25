/// Supabase configuration for storage
class SupabaseConfig {
  static const String projectId = 'pjqchcpnbjxcuvrevaht';
  static const String url = 'https://pjqchcpnbjxcuvrevaht.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqcWNoY3BuYmp4Y3V2cmV2YWh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1OTU3NzgsImV4cCI6MjA4MjE3MTc3OH0.Ax1gI-Y201gSzbXrL1kEFhzsCl-vrkliEV8m8n5JQXI';
  static const String bucket = 'auctionimages';
  
  /// Get public URL for a stored image
  static String getPublicUrl(String path) {
    return '$url/storage/v1/object/public/$bucket/$path';
  }
  
  /// Storage API endpoint
  static String get storageUrl => '$url/storage/v1';
}
