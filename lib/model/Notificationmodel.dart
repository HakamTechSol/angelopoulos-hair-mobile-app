class NotificationItem {
  final String title;
  final String subtitle;
  final String timeAgo;
  final String iconPath;
  final bool isUnread;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.iconPath,
    this.isUnread = false,
  });
}
