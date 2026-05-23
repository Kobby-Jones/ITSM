class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Shell
  static const home = '/home';                      // role-aware dashboard
  static const tickets = '/tickets';
  static const ticketDetail = '/tickets/:id';       // /tickets/T-1029
  static const submitTicket = '/tickets/new';
  static const knowledgeBase = '/kb';
  static const kbArticle = '/kb/:id';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const profile = '/profile';
  static const search = '/search';

  // Technician
  static const ticketQueue = '/queue';
  static const slaMonitor = '/sla-monitor';
  static const ticketResolution = '/tickets/:id/resolve';
  static const telemetryAnalysis = '/tickets/:id/telemetry';

  // Admin
  static const assets = '/assets';
  static const assetDetail = '/assets/:id';
  static const userManagement = '/admin/users';
  static const kbManagement = '/admin/kb';
  static const routingRules = '/admin/routing';
  static const slaConfig = '/admin/sla';

  // Manager
  static const analytics = '/analytics';
  static const kpiDashboard = '/analytics/kpis';
  static const technicianPerformance = '/analytics/technicians';
  static const slaCompliance = '/analytics/sla';
  static const reports = '/analytics/reports';

  // Sync
  static const syncQueue = '/sync';
  static const offline = '/offline';

  static String ticketDetailFor(String id) => '/tickets/$id';
  static String kbArticleFor(String id) => '/kb/$id';
  static String assetDetailFor(String id) => '/assets/$id';
  static String resolveFor(String id) => '/tickets/$id/resolve';
  static String telemetryFor(String id) => '/tickets/$id/telemetry';
}
