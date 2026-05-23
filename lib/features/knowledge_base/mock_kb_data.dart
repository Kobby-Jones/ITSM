import '../../models/kb_article.dart';

class MockKbData {
  static List<KbArticle> generate() {
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));

    return [
      KbArticle(
        id: 'kb-001',
        title: 'How to connect to the company VPN',
        summary: 'Step-by-step guide for configuring and connecting to the Goldfields Ghana VPN on Windows and Android.',
        content: '''
The Goldfields Ghana VPN provides secure access to internal resources when working off-site or from a non-trusted network.

## Prerequisites

- A valid Goldfields Ghana account (the same credentials you use for email).
- Two-factor authentication configured.
- The Cisco Secure Client (formerly AnyConnect) installed on your device.

## Connecting on Windows

1. Open Cisco Secure Client from the Start Menu.
2. In the connection field, enter `vpn.goldfields.gh` and click Connect.
3. Enter your username and password.
4. Approve the push notification on your phone.
5. The shield icon in the system tray will turn green when connected.

## Connecting on Android

1. Install Cisco Secure Client from the Play Store.
2. Tap "Add New Connection" and enter `vpn.goldfields.gh`.
3. Enter your credentials and approve 2FA.
4. The connection will remain active in the background.

## Troubleshooting

- If you cannot connect, check that you have an active internet connection first.
- If 2FA fails, contact IT to verify your phone number on file.
- Disable any other VPN apps before connecting — they can interfere.

## Related

- KB-007: Resetting your 2FA token
- KB-014: Working from a remote site
''',
        category: KbCategory.network,
        tags: const ['vpn', 'remote', 'connectivity', 'cisco', 'security'],
        author: 'IT Operations',
        updatedAt: ago(12),
        views: 1842,
        helpfulVotes: 287,
        relatedArticles: const ['kb-007', 'kb-014'],
        readMinutes: 4,
      ),
      KbArticle(
        id: 'kb-002',
        title: 'My printer is offline — what do I do?',
        summary: 'Common fixes for printers that show as offline, including network checks and print queue resets.',
        content: '''
A printer showing offline is usually one of these three issues: a paused queue, a network problem, or stale driver state.

## First, try the obvious

- Is the printer powered on? Check the display panel.
- Is the cable / wireless connection lit?
- Is there paper and toner?

## Reset the print queue

1. Open Settings → Bluetooth & devices → Printers & scanners.
2. Click the printer → Open print queue.
3. Cancel any stuck jobs.
4. Right-click the printer → Use printer offline (uncheck if checked).

## Restart the print spooler

1. Press Win+R, type `services.msc`, hit Enter.
2. Find "Print Spooler" → right-click → Restart.

## Reinstall the driver

If the above does not help, raise a ticket — IT will need to reinstall the driver remotely.

## Related

- KB-018: Setting your default printer
- KB-022: Scan-to-email setup
''',
        category: KbCategory.troubleshooting,
        tags: const ['printer', 'offline', 'queue', 'driver'],
        author: 'IT Operations',
        updatedAt: ago(28),
        views: 1340,
        helpfulVotes: 198,
        relatedArticles: const ['kb-018', 'kb-022'],
        readMinutes: 3,
      ),
      KbArticle(
        id: 'kb-003',
        title: 'Setting up Outlook on a new device',
        summary: 'Configure your work email on Outlook for desktop and mobile.',
        content: '''
Outlook auto-discovers most settings if you sign in with your Goldfields Ghana email.

## On Windows

1. Open Outlook.
2. Enter your email (e.g. firstname.lastname@goldfields.gh).
3. Approve the 2FA prompt.
4. Outlook will pull the settings automatically.

## On mobile

Use the Microsoft Outlook app from your app store. Avoid third-party email clients — they may not get the security policies right.

## Common issues

- "Cannot connect to server" → check VPN/internet connection.
- Repeated password prompts → see KB-005.
''',
        category: KbCategory.email,
        tags: const ['outlook', 'email', 'setup', 'mobile'],
        author: 'IT Operations',
        updatedAt: ago(45),
        views: 980,
        helpfulVotes: 156,
        relatedArticles: const ['kb-005'],
        readMinutes: 3,
      ),
      KbArticle(
        id: 'kb-004',
        title: 'Requesting access to a SharePoint site',
        summary: 'How to request access to department SharePoint folders and the typical approval timeline.',
        content: '''
Department SharePoint sites are owned by the department head. Access must be requested and approved.

## How to request

1. Submit a ticket under category "Account Access & Identity".
2. Specify the SharePoint URL or department name.
3. Specify whether you need read or read/write access.
4. Justify the access in 1-2 sentences.

## Timeline

- IT validates the request within 1 working day.
- Department head approves within 1-2 working days.
- IT applies the permissions within a few hours after approval.

## Removing access

When you change roles or leave the department, raise a ticket to have access removed. This is also done automatically during quarterly access reviews.
''',
        category: KbCategory.security,
        tags: const ['sharepoint', 'access', 'permissions'],
        author: 'IT Administration',
        updatedAt: ago(60),
        views: 612,
        helpfulVotes: 89,
        relatedArticles: const [],
        readMinutes: 2,
      ),
      KbArticle(
        id: 'kb-005',
        title: 'Outlook keeps asking for my password',
        summary: 'Fixes for the recurring credential prompt in Outlook.',
        content: '''
This is usually caused by stale cached credentials.

## Clear cached credentials

1. Open Control Panel → User Accounts → Credential Manager.
2. Click "Windows Credentials".
3. Delete any entries starting with "MicrosoftOffice…" or "msteams_adalsso/…".
4. Restart Outlook.

## If that does not work

- Sign out of all Office apps.
- Restart the computer.
- Sign back in.

If still failing, raise a ticket — IT may need to reset your token.
''',
        category: KbCategory.email,
        tags: const ['outlook', 'password', 'credentials', '2fa'],
        author: 'IT Operations',
        updatedAt: ago(70),
        views: 890,
        helpfulVotes: 142,
        relatedArticles: const ['kb-003'],
        readMinutes: 2,
      ),
      KbArticle(
        id: 'kb-006',
        title: 'Plant SCADA terminal — basic troubleshooting',
        summary: 'First-line checks for the CIL plant SCADA terminal at Tarkwa.',
        content: '''
Before raising a P1, please run through these checks (this resolves about 60% of incidents).

## Check the terminal

1. Is the terminal powered on?
2. Is the screen frozen? Try moving the mouse — if the cursor does not move, the terminal has hung.
3. Reboot ONLY if production permits — never during a critical process.

## Check the network

1. Look at the network LED on the terminal — should be solid green.
2. Open a Command Prompt and run: `ping 10.42.18.5` (the OPC server).

## If the OPC server is unreachable

- This is a P1. Raise a ticket immediately and call IT directly.
- Do not attempt to restart the OPC server yourself.

## Related

- KB-019: Operator handover checklist
''',
        category: KbCategory.troubleshooting,
        tags: const ['scada', 'plant', 'production', 'opc'],
        author: 'IT Operations',
        updatedAt: ago(20),
        views: 423,
        helpfulVotes: 71,
        relatedArticles: const [],
        readMinutes: 4,
      ),
      KbArticle(
        id: 'kb-007',
        title: 'Resetting your two-factor authentication',
        summary: 'How to set up 2FA on a new phone or after losing access.',
        content: '''
2FA must be reset by IT — for security, you cannot do it yourself.

## What to prepare

- Your new phone (or replacement device).
- Your employee ID.
- Be ready to be on a video call so IT can verify your identity.

## How long it takes

Usually 15-30 minutes once IT picks up the ticket. We treat this as P2.
''',
        category: KbCategory.security,
        tags: const ['2fa', 'mfa', 'security', 'phone'],
        author: 'IT Administration',
        updatedAt: ago(35),
        views: 510,
        helpfulVotes: 88,
        relatedArticles: const ['kb-001'],
        readMinutes: 2,
      ),
      KbArticle(
        id: 'kb-008',
        title: 'Onboarding checklist for new starters',
        summary: 'What IT does for a new starter, and what the line manager needs to provide.',
        content: '''
This is the standard new-starter IT setup at Goldfields Ghana.

## What the line manager submits (at least 5 days before the start date)

- Full name, role, department, location.
- Email address (firstname.lastname@goldfields.gh).
- Any special software requirements (e.g. ArcGIS for geologists).
- Hardware preference (laptop vs desktop).

## What IT delivers

- Account in Active Directory + Microsoft 365.
- Issued laptop with the standard image.
- Access to the department SharePoint and shared drives.
- Email signature template applied.
- 2FA setup on day one.

## Day-one checklist for the new starter

- Sign in to your laptop using your work email.
- Set up 2FA using the Microsoft Authenticator app.
- Open Outlook — confirm email is working.
- Open Teams — join your team's channels.
- Review the IT acceptable use policy (linked in KB-011).
''',
        category: KbCategory.gettingStarted,
        tags: const ['onboarding', 'new starter', 'setup'],
        author: 'IT Administration',
        updatedAt: ago(90),
        views: 308,
        helpfulVotes: 64,
        relatedArticles: const ['kb-011'],
        readMinutes: 5,
      ),
      KbArticle(
        id: 'kb-009',
        title: 'Free up disk space on your laptop',
        summary: 'Quick wins to recover storage when your laptop is full.',
        content: '''
Most full-disk issues are caused by Outlook caches, Teams caches, and old downloads.

## Quick wins

1. Empty the Downloads folder (move important files first).
2. Empty the Recycle Bin.
3. Run Windows Disk Cleanup → tick "Temporary files" and "Previous Windows installations".

## Outlook cache

- Outlook keeps a copy of your mailbox locally. If your mailbox is large (>30 GB), the cache can be huge.
- Reduce it: File → Account Settings → Data Files → Reduce mailbox size.

## Teams cache

Close Teams, then delete the contents of:

`%appdata%\\Microsoft\\Teams\\Cache`

Restart Teams.

If you have done all this and still have less than 10 GB free, raise a ticket.
''',
        category: KbCategory.hardware,
        tags: const ['storage', 'disk', 'cleanup', 'cache'],
        author: 'IT Operations',
        updatedAt: ago(110),
        views: 225,
        helpfulVotes: 38,
        relatedArticles: const [],
        readMinutes: 3,
      ),
      KbArticle(
        id: 'kb-010',
        title: 'Reporting a phishing email',
        summary: 'How to flag suspicious emails to the security team — and what NOT to do.',
        content: '''
If you receive a suspicious email, do not click any links or download attachments.

## Reporting

- In Outlook: click the "Report" button → "Phishing".
- The email will be sent to security@goldfields.gh and removed from your inbox.

## What you should NOT do

- Do not forward the email to colleagues — it spreads risk.
- Do not reply, even to "unsubscribe".
- Do not click any link, even one labelled "Report this email".

## What to look out for

- Urgency: "Your password expires in 1 hour."
- Mismatch: sender name says "Goldfields IT" but address is gibberish@unknown.com.
- Unexpected attachments, especially zip files or invoices.
- Links that hover-show a different URL than the visible text.

If you have already clicked something suspicious, raise a ticket immediately and disconnect the device from the network.
''',
        category: KbCategory.security,
        tags: const ['phishing', 'email', 'security', 'fraud'],
        author: 'Security Team',
        updatedAt: ago(8),
        views: 1102,
        helpfulVotes: 215,
        relatedArticles: const [],
        readMinutes: 3,
      ),
      KbArticle(
        id: 'kb-011',
        title: 'Acceptable use policy summary',
        summary: 'Brief, plain-language summary of what is and is not allowed on company devices.',
        content: '''
The full policy is on the intranet. Here is the short version.

## You may

- Use company devices for short personal tasks (email, banking, news).
- Install approved software from the IT software catalogue.
- Use cloud services that have been pre-approved.

## You may not

- Install pirated or unlicensed software.
- Disable security tools (antivirus, encryption, firewall).
- Share your password with anyone, including IT.
- Connect personal storage devices that have not been scanned.
- Use the network for high-bandwidth personal entertainment (streaming, large downloads).

## Consequences

Policy breaches are reviewed by HR and Security. Repeated breaches can lead to disciplinary action.
''',
        category: KbCategory.security,
        tags: const ['policy', 'aup', 'compliance'],
        author: 'IT Administration',
        updatedAt: ago(180),
        views: 642,
        helpfulVotes: 41,
        relatedArticles: const [],
        readMinutes: 3,
      ),
      KbArticle(
        id: 'kb-012',
        title: 'Slow PowerBI report — what to check',
        summary: 'When a PowerBI dashboard runs slowly, here is the order to investigate.',
        content: '''
PowerBI slowness is usually a data refresh issue, not a network issue.

## Check the data refresh status

1. In PowerBI, click File → Settings → Datasets.
2. Look at the last refresh time. If it is more than 24 hours stale, refresh manually.
3. If the refresh fails, check the credentials.

## Network checks

- Are you on the VPN? Some data sources require it.
- Run a speed test — anything below 10 Mbps will be visibly slow.

## Reduce the data range

If the report is fundamentally heavy (e.g. 5 years of daily data), consider filtering down to the last quarter and exporting only what you need.
''',
        category: KbCategory.software,
        tags: const ['powerbi', 'reports', 'performance', 'analytics'],
        author: 'IT Operations',
        updatedAt: ago(15),
        views: 188,
        helpfulVotes: 27,
        relatedArticles: const [],
        readMinutes: 3,
      ),
    ];
  }
}
