class ApiConfig {
  // Replace this with your production Vercel/Netlify URL, or use the local emulator fallback
  static const String baseUrl = 'http://10.92.43.46:3000'; // Default to Android Emulator local host
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/callback/credentials';
  static const String csrfEndpoint = '/api/auth/csrf';
  static const String sessionEndpoint = '/api/auth/session';
  static const String syncEndpoint = '/api/auth/sync';
  
  static const String recipesEndpoint = '/api/recipes';
  static const String recommendEndpoint = '/api/recipes/recommend';
  static const String plannerEndpoint = '/api/planner';
  static const String groceryEndpoint = '/api/grocery';
  static const String groceryGenerateEndpoint = '/api/grocery/generate';
  static const String statsEndpoint = '/api/admin/stats';
}
