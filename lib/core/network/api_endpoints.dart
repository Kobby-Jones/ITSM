/// Endpoint paths, relative to `Env.baseUrl` (which already includes
/// `/api/v1`). Kept in one place so a backend route rename only needs to
/// change here, not in every service file.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh-token';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const changePassword = '/auth/change-password';

  // Tickets
  static const tickets = '/tickets';
  static String ticket(String id) => '/tickets/$id';
  static String ticketAssign(String id) => '/tickets/$id/assign';
  static String ticketStatus(String id) => '/tickets/$id/status';
  static String ticketEscalate(String id) => '/tickets/$id/escalate';
  static String ticketComments(String id) => '/tickets/$id/comments';
  static String ticketHistory(String id) => '/tickets/$id/history';

  // Users / technicians
  static const users = '/users';
  static const technicians = '/users/technicians';
  static const meStats = '/users/me/stats';
  static String user(String id) => '/users/$id';
  static String userStats(String id) => '/users/$id/stats';

  // Assets
  static const assets = '/assets';
  static const assetStats = '/assets/stats';
  static String asset(String id) => '/assets/$id';
  static String assetHistory(String id) => '/assets/$id/history';
  static String assetAssign(String id) => '/assets/$id/assign';
  static String assetReturn(String id) => '/assets/$id/return';

  // Knowledge base
  static const kbArticles = '/knowledge-base';
  static const kbCategories = '/knowledge-base/categories';
  static String kbArticle(String id) => '/knowledge-base/$id';
  static String kbRate(String id) => '/knowledge-base/$id/rate';

  // Notifications
  static const notifications = '/notifications';
  static const notificationsUnreadCount = '/notifications/unread-count';
  static const notificationsMarkAllRead = '/notifications/mark-all-read';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notification(String id) => '/notifications/$id';

  // Sync (offline-first batch replay)
  static const syncBatch = '/sync/batch';
  static const syncQueue = '/sync/queue';
  static const syncStatus = '/sync/status';

  // Analytics
  static const analyticsDashboard = '/analytics/dashboard';
  static const analyticsTrends = '/analytics/trends';
  static const analyticsTechnicianPerformance = '/analytics/technician-performance';
  static const analyticsResolutionTime = '/analytics/resolution-time';
  static const analyticsCategoryBreakdown = '/analytics/category-breakdown';

  // SLA
  static const slaConfigurations = '/sla/configurations';
  static String slaConfiguration(String priority) => '/sla/configurations/$priority';
  static String slaTicketStatus(String ticketId) => '/sla/tickets/$ticketId/status';
  static const slaReport = '/sla/report';

  // Routing rules
  static const routing = '/routing';
  static String routingRule(String id) => '/routing/$id';
  static String routingRuleTest(String id) => '/routing/$id/test';

  // Telemetry
  static const telemetry = '/telemetry';
  static const telemetryDevices = '/telemetry/devices';
  static String telemetryForDevice(String deviceId) => '/telemetry/devices/$deviceId';
  static String telemetryLogsForDevice(String deviceId) => '/telemetry/devices/$deviceId/logs';
}
