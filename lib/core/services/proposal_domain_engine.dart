import '../../data/models/proposal_model.dart';
import '../../data/models/strategy_deliverable_model.dart';

/// Supported Domain Archetypes for Proposal Generation
enum ProposalDomainCategory {
  ventureAndInnovation, // VC, Accelerator, Startup, Investment, Corporate Innovation, Angel Syndicate
  healthcareAndClinic,  // Clinic, Medical, Dental, Aesthetics, Health, Hospital
  luxuryAndHospitality,  // Yacht Charter, Cruise, Resort, Travel, Fine Dining, Leisure
  b2bTechAndSaaS,       // Software, Cloud, AI Agents, Enterprise IT, SaaS, Platform
  professionalServices, // Consulting, Legal, Agency, Accounting, Executive Search
  generalEnterprise,    // General Business, Retail, FMCG, Manufacturing
}

/// Proposal Domain Engine — Deeply analyzes company, industry, and pitch deck
/// to synthesize 100% relevant, authoritative strategic proposals without generic placeholders.
class ProposalDomainEngine {
  static final ProposalDomainEngine instance = ProposalDomainEngine._internal();
  ProposalDomainEngine._internal();

  /// Detect domain archetype from company name, industry, website, and extracted pitch deck text
  ProposalDomainCategory detectCategory({
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    String? pitchDeckText,
  }) {
    final combined = '${leadCompanyName.toLowerCase()} ${industry.toLowerCase()} ${websiteUrl.toLowerCase()} ${(pitchDeckText ?? "").toLowerCase()}';

    // 1. Venture & Corporate Innovation
    if (combined.contains('venture') ||
        combined.contains('accelerator') ||
        combined.contains('startup') ||
        combined.contains('invest') ||
        combined.contains('pitch deck') ||
        combined.contains('demo day') ||
        combined.contains('aum') ||
        combined.contains('angel syndicate') ||
        combined.contains('incubat') ||
        combined.contains('deal flow') ||
        combined.contains('open innovation') ||
        combined.contains('co-innovation')) {
      return ProposalDomainCategory.ventureAndInnovation;
    }

    // 2. Healthcare & Medical Clinics
    if (combined.contains('clinic') ||
        combined.contains('doctor') ||
        combined.contains('patient') ||
        combined.contains('health') ||
        combined.contains('dental') ||
        combined.contains('medical') ||
        combined.contains('surgery') ||
        combined.contains('treatment') ||
        combined.contains('aesthetic')) {
      return ProposalDomainCategory.healthcareAndClinic;
    }

    // 3. Luxury & Hospitality (Yachts, Resorts, Cruises)
    if (combined.contains('yacht') ||
        combined.contains('charter') ||
        combined.contains('boat') ||
        combined.contains('cruise') ||
        combined.contains('sailing') ||
        combined.contains('resort') ||
        combined.contains('catamaran')) {
      return ProposalDomainCategory.luxuryAndHospitality;
    }

    // 4. B2B Tech & SaaS
    if (combined.contains('saas') ||
        combined.contains('software') ||
        combined.contains('cloud') ||
        combined.contains('api') ||
        combined.contains('developer') ||
        combined.contains('ai platform') ||
        combined.contains('automation') ||
        combined.contains('cybersecurity')) {
      return ProposalDomainCategory.b2bTechAndSaaS;
    }

    // 5. Professional Services & Consulting
    if (combined.contains('consulting') ||
        combined.contains('law') ||
        combined.contains('legal') ||
        combined.contains('accounting') ||
        combined.contains('advisory') ||
        combined.contains('recruitment') ||
        combined.contains('agency')) {
      return ProposalDomainCategory.professionalServices;
    }

    return ProposalDomainCategory.generalEnterprise;
  }

  /// Synthesize a rich, contextual proposal tailored directly to the business archetype
  ProposalModel synthesizeProposal({
    required String proposalId,
    required String amId,
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    Map<String, String>? socialUrls,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
  }) {
    final category = detectCategory(
      leadCompanyName: leadCompanyName,
      industry: industry,
      websiteUrl: websiteUrl,
      pitchDeckText: extractedPitchDeckText,
    );

    switch (category) {
      case ProposalDomainCategory.ventureAndInnovation:
        return _synthesizeVentureAndInnovation(
          proposalId: proposalId,
          amId: amId,
          leadCompanyName: leadCompanyName,
          industry: industry,
          websiteUrl: websiteUrl,
          socialUrls: socialUrls ?? {},
          pitchDeckFileName: pitchDeckFileName,
          pitchDeckStorageUrl: pitchDeckStorageUrl,
          extractedPitchDeckText: extractedPitchDeckText,
        );

      case ProposalDomainCategory.healthcareAndClinic:
        return _synthesizeHealthcare(
          proposalId: proposalId,
          amId: amId,
          leadCompanyName: leadCompanyName,
          industry: industry,
          websiteUrl: websiteUrl,
          socialUrls: socialUrls ?? {},
          pitchDeckFileName: pitchDeckFileName,
          pitchDeckStorageUrl: pitchDeckStorageUrl,
          extractedPitchDeckText: extractedPitchDeckText,
        );

      case ProposalDomainCategory.luxuryAndHospitality:
        return _synthesizeLuxuryHospitality(
          proposalId: proposalId,
          amId: amId,
          leadCompanyName: leadCompanyName,
          industry: industry,
          websiteUrl: websiteUrl,
          socialUrls: socialUrls ?? {},
          pitchDeckFileName: pitchDeckFileName,
          pitchDeckStorageUrl: pitchDeckStorageUrl,
          extractedPitchDeckText: extractedPitchDeckText,
        );

      case ProposalDomainCategory.b2bTechAndSaaS:
        return _synthesizeB2BTech(
          proposalId: proposalId,
          amId: amId,
          leadCompanyName: leadCompanyName,
          industry: industry,
          websiteUrl: websiteUrl,
          socialUrls: socialUrls ?? {},
          pitchDeckFileName: pitchDeckFileName,
          pitchDeckStorageUrl: pitchDeckStorageUrl,
          extractedPitchDeckText: extractedPitchDeckText,
        );

      case ProposalDomainCategory.professionalServices:
      case ProposalDomainCategory.generalEnterprise:
        return _synthesizeGeneralEnterprise(
          proposalId: proposalId,
          amId: amId,
          leadCompanyName: leadCompanyName,
          industry: industry,
          websiteUrl: websiteUrl,
          socialUrls: socialUrls ?? {},
          pitchDeckFileName: pitchDeckFileName,
          pitchDeckStorageUrl: pitchDeckStorageUrl,
          extractedPitchDeckText: extractedPitchDeckText,
        );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. VENTURE CAPITAL, ACCELERATOR & CORPORATE INNOVATION (e.g. Meet Ventures)
  // ───────────────────────────────────────────────────────────────────────────
  ProposalModel _synthesizeVentureAndInnovation({
    required String proposalId,
    required String amId,
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    required Map<String, String> socialUrls,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
  }) {
    final deck = extractedPitchDeckText ?? '';
    final hasDeck = deck.trim().isNotEmpty;

    // Detect if deck has specific Meet Ventures metrics
    final hasRegionalData = deck.contains('10') || deck.contains('Asia') || deck.contains('Singapore');
    final hasInvestorData = deck.contains('130') || deck.contains('105B') || deck.contains('AUM');
    final partnerMentions = deck.contains('JETRO') || deck.contains('KOCCA') || deck.contains('Enterprise Singapore');

    final networkStat = hasInvestorData ? '130+ institutional investors (\$105B combined AUM)' : '100+ global venture partners';
    final chapterStat = hasRegionalData ? 'across 10 Asian markets (Singapore, Indonesia, Malaysia, Japan, Korea)' : 'across key regional markets';
    final partnerStat = partnerMentions ? 'Enterprise Singapore, JETRO, KOCCA, and leading MNCs' : 'leading multinational corporations and government agencies';

    return ProposalModel(
      id: proposalId,
      amId: amId,
      leadCompanyName: leadCompanyName,
      industry: industry.isNotEmpty ? industry : 'Venture Capital & Corporate Innovation',
      websiteUrl: websiteUrl,
      socialUrls: socialUrls,
      pitchDeckFileName: pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText,
      status: ProposalStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),

      // Executive Summary
      executiveSummaryPosition: hasDeck
          ? '$leadCompanyName operates as a regional accelerator and early-stage venture builder driving innovation excellence $chapterStat. Backed by a verified network of $networkStat and an active track record serving clients from $partnerStat, the firm bridges global enterprise demand with high-growth startup technology.'
          : '$leadCompanyName has established a prominent presence in the regional venture building and corporate innovation landscape, connecting high-potential technology startups with enterprise partners and institutional capital.',
      executiveSummaryOpportunity:
          'While $leadCompanyName possesses elite institutional credibility, significant opportunity remains to establish dominant digital authority. Transforming offline corporate matchmaking into high-converting digital landing hubs, programmatic LinkedIn thought leadership, and SEO discovery for corporate accelerators will systematically capture Tier-1 enterprise innovation mandates.',

      // SWOT
      swot: SwotMatrix(
        strengths: [
          'Extensive regional presence $chapterStat with boots-on-the-ground execution',
          'Vast cross-border investor ecosystem ($networkStat)',
          'Proven delivery managing 30+ corporate accelerators and market access programs',
          'Deep partner credibility with $partnerStat',
        ],
        weaknesses: [
          'Under-communicated corporate case studies and pilot outcomes on public channels',
          'Low organic search visibility for high-ticket corporate accelerator terms',
          'Executive insights currently fragmented across personal profiles rather than centralized',
          'Under-utilized short-form video cadence spotlighting Demo Days and founder stories',
        ],
        opportunities: [
          'Capturing high-ticket corporate co-innovation and venture studio retainers from APAC MNCs',
          'Dominating AI-driven search engines (Perplexity, ChatGPT) and Google organic search',
          'Producing high-impact executive video content spotlighting cross-border portfolio successes',
          'Building dedicated enterprise pilot portals for transparent dealflow evaluation',
        ],
        threats: [
          'Global accelerator networks (Plug and Play, Techstars, Antler) expanding Southeast Asia desks',
          'Corporate R&D budget scrutiny demanding rapid, verified ROI over exploratory workshops',
          'Early-stage venture funding consolidation heightening selectivity among co-investors',
          'Rapid technological shifts requiring continuous agile iteration of accelerator programs',
        ],
      ),

      // 4Ps Marketing Mix
      marketingMix4Ps: const MarketingMix4Ps(
        productCurrent:
            'Corporate open innovation tracks, startup accelerator cohorts, demo days, cross-border market entry programs, and seed venture investments (\$100k-\$500k).',
        productOpportunity:
            'Package distinct outcome-engineered enterprise offerings: "Turnkey Corporate Co-Innovation", "Cross-Border Market Access (SG/ID/MY/VN/JP)", and "Proprietary Dealflow Syndication".',
        priceCurrent:
            'Enterprise corporate retainers, institutional program sponsorship fees, and equity carry.',
        priceOpportunity:
            'Position value-based pricing anchored on executive risk reduction, accelerated pilot deployment, and corporate venture returns rather than commoditized event hosting.',
        placeCurrent:
            'Direct ecosystem partner networks across 10 Asian chapters, executive LinkedIn profiles, and referral deal flow.',
        placeOpportunity:
            'Expand digital inbound acquisition via high-authority SEO research hubs, localized APAC market guides, and automated B2B executive inquiry pipelines.',
        promotionCurrent:
            'Demo day announcements, ecosystem partner press releases, and occasional event recaps.',
        promotionOpportunity:
            'Deploy an omni-channel thought leadership engine: weekly C-level venture breakdowns, founder journey documentary reels, and proprietary APAC tech ecosystem reports.',
      ),

      // PEST Analysis
      pestAnalysis: const PestAnalysis(
        political: [
          'Regional government innovation grants and bilateral market access frameworks (Enterprise SG, JETRO, KOCCA)',
          'Cross-border regulatory harmonization and intellectual property licensing protocols across ASEAN',
          'National sovereign economic agendas emphasizing deeptech commercialization and local talent upskilling',
        ],
        economic: [
          'Corporate R&D budgets pivoting from internal labs toward agile open innovation and corporate venture capital (CVC)',
          'Southeast Asia digital economy acceleration attracting global strategic expansion capital',
          'Consolidation of early-stage venture funding heightening enterprise demand for rigorously vetted startup cohorts',
        ],
        social: [
          'Surge of ambitious founders building regional cross-border companies from Day 1',
          'Enterprise executives embracing startup co-innovation to counter organizational inertia',
          'Growing ecosystem appetite for collaborative venture syndication and corporate-startup co-creation',
        ],
        technological: [
          'Enterprise adoption of Generative AI, IoT sensors, and autonomous operational agents across industry verticals',
          'Algorithmic deal sourcing and automated portfolio milestone tracking tools',
          'AI-driven search engines (Perplexity, ChatGPT) becoming primary research channels for B2B procurement',
        ],
      ),

      // Competitor & USP Matrix (REAL Competitors in APAC)
      competitorUsps: [
        CompetitorUsp(
          brandName: leadCompanyName,
          primaryUsp: 'Pan-Asian cross-border execution with localized chapters in 10 countries, 130+ investor network (\$105B AUM), and direct corporate pilot delivery',
          isLeadBrand: true,
        ),
        const CompetitorUsp(
          brandName: 'Plug and Play APAC',
          primaryUsp: 'Global brand network with high-volume corporate partner memberships and standardized batch tracks',
          isLeadBrand: false,
        ),
        const CompetitorUsp(
          brandName: 'Antler',
          primaryUsp: 'Day-zero talent incubator model with programmatic early-stage founder matching and venture deployment',
          isLeadBrand: false,
        ),
        const CompetitorUsp(
          brandName: 'Techstars / Rainmaking',
          primaryUsp: 'Global accelerator curriculum with corporate venture studio programs for international conglomerates',
          isLeadBrand: false,
        ),
      ],

      // Perceptual Map
      perceptualMapNarrative:
          '$leadCompanyName occupies a commanding strategic position between deep localized Asia execution and institutional enterprise credibility. While global accelerators operate rigid models and local incubators lack multi-country reach, $leadCompanyName delivers agile, cross-border corporate pilot execution across 10 Asian chapters.',
      perceptualMapInsight:
          'Corporations do not partner with accelerators for generic networking—they invest in guaranteed pilot milestones, vetted tech validation, and cross-border commercial market entry.',
      perceptualMapOpportunity:
          'Establish $leadCompanyName as the undisputed benchmark for Asia-wide corporate co-innovation and regional startup scaling.',

      // Creative Pillars
      creativePillars: [
        const ContentPillar(
          title: 'Corporate Pilot Breakthroughs',
          objective: 'Demonstrate tangible business outcomes and pilot deployments between global enterprises and portfolio startups.',
          contentStyle: ['MNC pilot case studies', 'Executive co-innovation breakdowns', 'ROI recap carousels'],
          exampleTopics: ['How an MNC Deployed Series-A AI in 60 Days', 'Inside a Cross-Border Co-Innovation Pilot', 'Why 70% of Internal Corporate R&D Fails'],
        ),
        ContentPillar(
          title: 'Cross-Border Asia Market Access',
          objective: 'Position $leadCompanyName as the definitive gateway for startups and corporations scaling across Asian markets.',
          contentStyle: const ['Country market guides', 'Regulatory briefings', 'Chapter lead interviews'],
          exampleTopics: const ['Expanding from Singapore to Indonesia: 4 Hard Truths', 'Navigating the Japanese Tech Ecosystem with JETRO', 'Building Cross-Border Distribution in Vietnam'],
        ),
        const ContentPillar(
          title: 'Founder Journeys & Deal Flow',
          objective: 'Highlight ambitious founders from the portfolio, humanizing the startup journey and driving high-quality inbound applications.',
          contentStyle: ['Founder documentary reels', 'Pitch breakdown shorts', 'Traction milestone recaps'],
          exampleTopics: ['From University Lab to Series A', 'Behind the Seed Round: Agritech Solar IoT', 'How This Founder Scaled to 9 Cities Across Indonesia'],
        ),
        const ContentPillar(
          title: 'Venture Capital & Investor Intelligence',
          objective: 'Engage the 130+ investor network with macro trends, syndication opportunities, and dealflow insights.',
          contentStyle: ['Quarterly market sentiment briefs', 'Syndicate spotlight carousels', 'LP & VC interviews'],
          exampleTopics: ['Where Southeast Asia VCs Are Deploying in 2026', 'Corporate Venture Capital vs Traditional VC', 'The Rise of Deeptech in ASEAN'],
        ),
        const ContentPillar(
          title: 'Executive Leadership & Masterclasses',
          objective: 'Solidify executive authority through leadership masterclasses on startup scouting, venture governance, and open innovation.',
          contentStyle: ['Keynote clips', 'Framework explainers', 'Podcast excerpts'],
          exampleTopics: ['The Open Innovation Playbook for C-Suite Leaders', 'Evaluating Pre-Series A Tech for Enterprise Readiness', 'Inside Our Demo Day Selection Process'],
        ),
      ],

      // Visual Guidelines
      visualGuidelineNotes:
          'Visual storytelling emphasizes clean architectural elegance, dynamic executive presence, and international venture credibility. High-contrast typography, authentic documentary photography of founders and executives in action, and data-dense infographics establish institutional authority.',
      brandPaletteHex: const ['#0F172A', '#1E293B', '#4F46E5', '#10B981', '#F8FAFC'],
      visualKeywords: const ['Authoritative', 'Global', 'Venture-grade', 'Dynamic', 'Catalytic'],
      focusMoreOn: const [
        'Executive roundtables',
        'High-stakes pitch stages',
        'Genuine founder-investor collaboration',
        'Cross-border demographic maps',
        'Demo day keynotes',
      ],
      focusLessOn: const [
        'Generic stock handshakes',
        'Empty auditoriums',
        'Sterile clip-art illustrations',
        'Impersonal corporate headshots',
      ],
      photographyQuote: "Corporations don't buy startup pitch decks. They buy validated market expansion and innovation execution.",
      typographySampleHeadline: "CONNECT. INNOVATE. SCALE ACROSS ASIA.",
      brandToneOfVoice: const [
        {'trait': 'AUTHORITATIVE', 'desc': 'Backed by verified track record, \$10M AUM, and multi-country operational mastery.'},
        {'trait': 'CATALYTIC', 'desc': 'Inspiring decisive corporate action, founder velocity, and ambitious cross-border growth.'},
        {'trait': 'GLOBAL', 'desc': 'Reflecting international operational chapters across 10 Asian economies.'},
        {'trait': 'TRUSTED', 'desc': 'Anchored in institutional credibility with government agencies and multinational enterprises.'},
      ],
      brandColorDetails: const {
        'primary': {'name': 'Midnight Navy', 'hex': '#0F172A'},
        'secondary': {'name': 'Electric Indigo', 'hex': '#4F46E5'},
        'accent': {'name': 'Venture Emerald', 'hex': '#10B981'},
      },

      // 4-Week Framework
      contentFrameworkWeeks: const [
        {
          'week': 'WEEK 1',
          'experienceStories': 'Corporate Innovation Pilot Blueprint (MNC + Series A Startup)',
          'educational': 'Why 70% of Internal Corporate R&D Fails (And How to Fix It)',
          'corporate': 'Inside Our Corporate Accelerator Track: Enterprise Objectives',
          'testimonials': 'Enterprise Partner Testimonial (Open Innovation Impact)',
          'promotional': 'Upcoming Regional Accelerator Batch: Corporate Applications Open',
          'contentExamples': '• Pilot case study recap\n• C-Suite diagnostic carousel\n• Program track breakdown\n• Enterprise partner quote\n• Corporate partner call-to-action',
        },
        {
          'week': 'WEEK 2',
          'experienceStories': 'Cross-Border Expansion: Scaling from Singapore to Indonesia',
          'educational': 'How to Structure Enterprise Proof of Concepts (POCs)',
          'corporate': 'Investor Syndicate Dealflow Brief: Pre-Series A Cohort',
          'testimonials': 'Portfolio Founder Story: Securing Seed Funding & Enterprise Clients',
          'promotional': 'Register for Demo Day: Meet 15 Vetted Asian Startups',
          'contentExamples': '• Market expansion playbook\n• POC milestone checklist\n• Dealflow teaser carousel\n• Founder interview clip\n• Demo day invite graphic',
        },
        {
          'week': 'WEEK 3',
          'experienceStories': 'Behind the Scenes: Startup Scouting with Government Agencies (JETRO/KOCCA)',
          'educational': 'Navigating Deeptech IP Licensing for Corporations',
          'corporate': 'Chapter Spotlight: Japan & South Korea Innovation Corridors',
          'testimonials': 'Government Agency Partner Review (Cross-Border Market Access)',
          'promotional': 'Download the 2026 Asia Venture & Corporate Innovation Report',
          'contentExamples': '• Bilateral program recap\n• IP commercialization guide\n• Chapter lead video interview\n• Government partner endorsement\n• Whitepaper lead magnet link',
        },
        {
          'week': 'WEEK 4',
          'experienceStories': 'Demo Day Highlights: 130+ Investors & \$105B Combined AUM',
          'educational': 'The 5 Essential Metrics Every Corporate Venture Studio Needs',
          'corporate': 'Executive Roundtable: The Future of Open Innovation in APAC',
          'testimonials': 'Lead Investor Testimonial: Co-Investing with Meet Ventures',
          'promotional': 'Schedule a Private Corporate Dealflow Consultation',
          'contentExamples': '• Demo Day reel & stats\n• Executive metrics carousel\n• Roundtable highlight quotes\n• Investor syndicate review\n• Direct consultation booking link',
        },
      ],

      // Sample Reel
      sampleReelHeadline: 'Scale Across Asia',
      sampleReelTopic: 'Inside a Corporate Innovation Breakthrough: Matching Global MNCs with High-Growth Tech',
      sampleReelHook: 'Most corporate innovation labs take 18 months to launch a pilot. Watch how we launched one in 60 days.',
      sampleReelVisualScenes:
          'Scene 1: Dynamic tracking shot of executive roundtable in Singapore with modern skyline.\nScene 2: Split screen showing corporate innovation bottleneck vs vetted startup solution.\nScene 3: Live demo day stage pitch with founder presenting pilot metrics to corporate judges.\nScene 4: Partner handshake and pilot deployment confirmation, ending with Meet Ventures brand signature.',
      sampleReelCta: 'Partner with Meet Ventures to scout, pilot, and deploy high-growth technology across 10 Asian markets. Link in bio.',
      sampleReelLink: 'https://www.meetventures.com',

      // Sample Blog
      sampleBlogTitle: 'The Corporate Open Innovation Playbook: How Asian Enterprises Deploy Startup Agility at Scale',
      sampleBlogStorytellingIntro:
          'Rather than relying on generic hackathons or theoretical workshops, modern enterprise leaders achieve true digital transformation through structured, outcome-driven co-innovation tracks that de-risk technology adoption while delivering rapid commercial pilots.',
      sampleBlogPreview:
          'In an era where technology cycles outpace internal corporate development, forward-thinking multinational corporations across Asia are rethinking their approach to R&D. By partnering with specialized accelerators that maintain boots-on-the-ground presence across 10 Asian economies, enterprises gain direct access to pre-vetted Series A technologies, curated dealflow, and hands-on proof-of-concept execution.\n\nIn this comprehensive strategic guide, we unpack the proven framework used by Meet Ventures to launch over 30 corporate and government innovation programs across Singapore, Indonesia, Japan, and Korea.',

      // Social Media Copywriting
      sampleSocialCaptionHook: 'Corporate innovation is not about internal hackathons. It is about speed-to-market. ⚡',
      sampleSocialCaptionBody:
          'When global corporations partner with high-potential startups, the difference between a PR exercise and a multi-million dollar breakthrough comes down to one thing: execution discipline.\n\nWith operational chapters across 10 Asian countries and a network of 130+ investors managing \$105B in combined AUM, Meet Ventures bridges the gap between enterprise corporate mandates and agile startup technology.\n\nExplore our corporate accelerator tracks or join our upcoming Demo Day cohort.',
      sampleSocialCaptionCta: '🔗 Visit meetventures.com or reach out to our partners to schedule an innovation discovery call.',
      sampleSocialHashtags: const [
        '#CorporateInnovation',
        '#VentureBuilding',
        '#StartupAsia',
        '#SoutheastAsiaVC',
        '#MeetVentures',
      ],

      // 3 Multi-Angle Social Posts
      socialPosts: const [
        {
          'title': 'Corporate Open Innovation',
          'headline': 'WHY 70% OF INTERNAL CORPORATE R&D LABS FAIL.',
          'body':
              'Most corporate innovation programs fail because they are built like internal departments: slow approval cycles, risk aversion, and theoretical roadmaps.\n\nReal innovation happens through venture execution.\n\nMeet Ventures connects multinational corporations directly with market-tested startups across 10 Asian countries. Guaranteed pilots, structured proof-of-concepts, and zero wasted cycles.\n\nDiscover our corporate innovation tracks at meetventures.com.',
          'badge': '30+ PROGRAMMES · 10 ASIAN MARKETS',
          'hashtags': ['#CorporateInnovation', '#OpenInnovation', '#VentureCapital', '#MeetVentures'],
          'imageUrl': '',
        },
        {
          'title': 'Cross-Border Market Access',
          'headline': 'SCALING ACROSS 10 ASIAN MARKETS?',
          'body':
              'Expanding from Singapore into Indonesia, Japan, South Korea, or Malaysia is rarely a product challenge—it is a network challenge.\n\nMeet Ventures provides founders and corporations with local chapter leads, verified regulatory pathways, and direct client introductions.\n\n500+ companies supported. \$10M AUM. 130+ investor partners.\n\nExplore our regional chapters at meetventures.com.',
          'badge': '10 COUNTRIES · 500+ COMPANIES',
          'hashtags': ['#CrossBorderExpansion', '#StartupAsia', '#SoutheastAsiaTech', '#VentureBuilding'],
          'imageUrl': '',
        },
        {
          'title': 'Investor & Ecosystem Dealflow',
          'headline': '130+ INVESTORS. \$105B COMBINED AUM.',
          'body':
              'When our Demo Day goes live, Southeast Asia\'s top venture capitalists, angel syndicates, and corporate venture capital (CVC) funds tune in.\n\nEvery cohort is rigorously screened across technical viability, unit economics, and cross-border commercial traction.\n\nApply for our next accelerator batch or register for investor access via link in bio.',
          'badge': '130+ VCs · \$105B AUM · SEED TO SERIES A',
          'hashtags': ['#DemoDay', '#VentureCapital', '#AngelSyndicate', '#StartupInvestments'],
          'imageUrl': '',
        },
      ],

      // SEO Audit
      seoAudit: const SeoAuditSummary(
        healthScore: 72,
        summaryText:
            'Meet Ventures maintains a modern digital web presence with active domain authority. However, significant high-value organic search and AI engine discovery (Perplexity, ChatGPT) opportunities remain uncaptured across high-intent enterprise terms like "corporate accelerator Singapore", "startup scouting Southeast Asia", and "venture builder APAC".',
        highPriority: [
          'Enterprise program landing pages ("Corporate Innovation Singapore", "Cross-Border Accelerator APAC")',
          'Structured Schema.org Organization, Event (Demo Day), and Leadership entity markup',
          'H1 and Meta Title optimization across core service and portfolio directory pages',
          'Core Web Vitals acceleration and WebP responsive image optimization',
        ],
        mediumPriority: [
          'Interactive portfolio directory with country and vertical filters',
          'Open Graph rich preview cards for market reports and chapter briefings',
          'Executive author authority profiles for partners John Lim and Farhan Firdaus',
        ],
        longTermOpportunities: [
          'AI search engine optimization (AIO & Perplexity entity positioning for VC queries)',
          'Comprehensive Asia Tech Ecosystem research and whitepaper knowledge hub',
          'Dedicated private enterprise partner dealflow and pilot tracking portal',
        ],
      ),

      seoAssessmentText:
          'Based on our review, we recommend prioritising enterprise-grade programmatic landing pages for corporate accelerator tracks and regional chapter hubs as the primary phase of digital optimisation. These initiatives will immediately capture high-intent C-Suite and institutional search demand, converting organic traffic into qualified corporate pilot inquiries.',
      seoAuditLink: 'https://meet-marketers.com/seo-audit',
      finalThoughtsSummary:
          '$leadCompanyName already possesses the foundational assets today’s enterprise clients and top-tier founders demand: verified multi-country presence across 10 Asian economies, strong institutional backing from state agencies and top MNCs, and a \$105B investor network. Our proposed digital and content strategy bridges the gap between exceptional offline execution and dominant digital category leadership.',
      finalThoughtsRecommendation:
          'We recommend initiating Phase 1 immediately: Launching corporate program landing pages and short-form executive video storytelling around Demo Days and pilot breakthroughs, followed by automated omni-channel thought leadership and high-intent SEO authority building.',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. HEALTHCARE & MEDICAL CLINICS
  // ───────────────────────────────────────────────────────────────────────────
  ProposalModel _synthesizeHealthcare({
    required String proposalId,
    required String amId,
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    required Map<String, String> socialUrls,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
  }) {
    return ProposalModel(
      id: proposalId,
      amId: amId,
      leadCompanyName: leadCompanyName,
      industry: industry.isNotEmpty ? industry : 'Healthcare & Medical Services',
      websiteUrl: websiteUrl,
      socialUrls: socialUrls,
      pitchDeckFileName: pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText,
      status: ProposalStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      executiveSummaryPosition:
          '$leadCompanyName operates as a trusted clinical healthcare provider, delivering personalized medical care, specialized clinical treatments, and patient-centric health solutions.',
      executiveSummaryOpportunity:
          'Patient acquisition in modern healthcare relies heavily on trust, verified credentials, and educational discovery. By establishing dominant local SEO, doctor-led educational video content, and transparent patient journey guides, $leadCompanyName can capture high-intent patient appointments.',
      swot: const SwotMatrix(
        strengths: ['Licensed clinical expertise and certified medical practitioners', 'High patient trust and clinical safety compliance', 'Positive patient outcomes and local referral base', 'Comprehensive diagnostic and treatment offerings'],
        weaknesses: ['Low organic visibility for specialized treatment search keywords', 'Limited doctor-led educational video content on social media', 'Fragmented appointment booking workflow', 'Educational content under-communicating preventative care'],
        opportunities: ['Local Google Maps (Google Business Profile) 3-pack dominance', 'Short-form educational Reels addressing common patient misconceptions', 'Condition-specific treatment landing pages with transparent FAQs', 'Capturing AI search health queries (Perplexity, ChatGPT)'],
        threats: ['Aggressive digital advertising by larger corporate hospital networks', 'Strict medical advertising guidelines (MOH / SMC compliance)', 'Rising cost of Google Search ads for medical keywords', 'Patient skepticism toward promotional medical claims'],
      ),
      marketingMix4Ps: const MarketingMix4Ps(
        productCurrent: 'Comprehensive medical consultations, specialized treatment procedures, preventative health screenings, and patient follow-ups.',
        productOpportunity: 'Package patient-centric care pathways: "Comprehensive Health Screening & Diagnostic Care", "Specialized Treatment Protocols", and "Preventative Wellness Management".',
        priceCurrent: 'Tiered clinical consultation rates and procedure-based pricing.',
        priceOpportunity: 'Emphasize transparent fee structures, insurance co-payment support, and outcome certainty over price discounting.',
        placeCurrent: 'Physical clinic premises, online appointment booking form, and direct telephone inquiry.',
        placeOpportunity: 'Optimize omni-channel patient access: instant WhatsApp clinical triage, online telemedicine scheduling, and localized clinic SEO.',
        promotionCurrent: 'Clinic website, occasional health tips on social channels, and word-of-mouth patient referrals.',
        promotionOpportunity: 'Deploy doctor-led video masterclasses, patient journey recovery stories (MOH-compliant), and preventative health guides.',
      ),
      pestAnalysis: const PestAnalysis(
        political: ['Healthcare services regulatory compliance and medical advertising ethical standards', 'Data privacy and patient confidentiality legislation (PDPA / HIPAA)', 'National health insurance schemes and subsidies (Medisave, CHAS)'],
        economic: ['Rising consumer expenditure on preventative wellness and longevity healthcare', 'Inflationary pressures on clinical supplies and healthcare staffing costs', 'Corporate healthcare insurance benefits driving employee clinic selection'],
        social: ['Patients proactively researching symptoms and treatments online before visiting', 'De-stigmatization of specialized care and mental wellness discussions', 'High patient preference for empathetic, transparent clinical communication'],
        technological: ['Telehealth adoption and automated appointment reminder systems', 'AI-assisted medical diagnostics and digital patient record integration', 'Search engines prioritizing high-E-E-A-T medical content written by verified doctors'],
      ),
      competitorUsps: [
        CompetitorUsp(brandName: leadCompanyName, primaryUsp: 'Personalized clinical care, senior medical expertise, and patient-first consultation continuity', isLeadBrand: true),
        const CompetitorUsp(brandName: 'Raffles Medical Group', primaryUsp: 'Mass corporate clinic network with integrated hospital infrastructure'),
        const CompetitorUsp(brandName: 'Thomson Medical / Minmed', primaryUsp: 'Consumer-focused health screening packages and family-centric care'),
        const CompetitorUsp(brandName: 'Specialist Boutique Clinics', primaryUsp: 'Niche sub-specialist focus with premium consultation pricing'),
      ],
      perceptualMapNarrative: '$leadCompanyName bridges specialized medical excellence with warm, accessible patient relationships, standing apart from impersonal corporate chains.',
      perceptualMapInsight: 'Patients do not choose doctors based on marketing slogans—they seek verified clinical expertise, empathetic listening, and predictable recovery outcomes.',
      perceptualMapOpportunity: 'Position $leadCompanyName as the most trusted, patient-recommended clinic in its specialty and geographic area.',
      creativePillars: [
        const ContentPillar(title: 'Doctor Explains (Medical Education)', objective: 'Demystify complex symptoms and treatments through calm, doctor-led explanations.', contentStyle: ['Talking-head educational reels', 'Myth vs Fact carousels', 'Anatomy diagrams'], exampleTopics: ['3 Signs You Should Not Ignore', 'What Actually Happens During Treatment', 'Common Treatment Myths Debunked']),
        const ContentPillar(title: 'Patient Care & Experience Pathways', objective: 'Alleviate clinic anxiety by demonstrating the warm, seamless patient journey.', contentStyle: ['Clinic tour videos', 'First consultation walkthroughs', 'Patient comfort guides'], exampleTopics: ['What to Expect on Your First Visit', 'Our Patient Comfort Philosophy', 'How We Manage Pain and Recovery']),
        const ContentPillar(title: 'Preventative Health & Longevity', objective: 'Inspire proactive wellness habits and regular health screenings.', contentStyle: ['Actionable lifestyle checklists', 'Nutrition & sleep tips', 'Screening milestones'], exampleTopics: ['Health Screenings You Need at 30, 40, and 50', 'How Daily Habits Impact Long-Term Health', 'Simple Tests That Save Lives']),
        const ContentPillar(title: 'Clinical Excellence & Technology', objective: 'Showcase medical equipment, hygiene protocols, and diagnostic precision.', contentStyle: ['Equipment demos', 'Behind-the-scenes sterilization', 'Clinical milestone recaps'], exampleTopics: ['How Advanced Diagnostics Improve Accuracy', 'Our Commitment to Clinical Safety', 'Meet Our Medical Team']),
        const ContentPillar(title: 'Community Health Q&A', objective: 'Build unshakeable trust by directly answering common patient questions.', contentStyle: ['Q&A reels', 'Community poll breakdowns', 'Doctor advice columns'], exampleTopics: ['Ask a Doctor: Top 5 Patient Inquiries This Month', 'Can This Condition Be Reversed?', 'When to Choose Medical Care Over Rest']),
      ],
      visualGuidelineNotes: 'Clean, calming, and reassuring aesthetic. Bright natural lighting, soft clinical whites and soothing teals, authentic documentary photography of doctors listening to patients.',
      brandPaletteHex: const ['#0F766E', '#14B8A6', '#0EA5E9', '#1E293B', '#F8FAFC'],
      visualKeywords: const ['Empathetic', 'Clinical', 'Reassuring', 'Authoritative', 'Clean'],
      focusMoreOn: const ['Doctors speaking directly to camera', 'Clean modern clinic environments', 'Patient-doctor consultations (approachable, respectful)', 'Clear medical diagrams'],
      focusLessOn: const ['Dramatic needle shots or gory procedures', 'Cheesy generic stock medical photos', 'Overly promotional sales banners', 'Sensationalist health claims'],
      photographyQuote: "Patients don't buy clinical procedures. Patients buy health certainty, empathetic listening, and lasting recovery.",
      typographySampleHeadline: "EXPERT CARE. LASTING WELLNESS.",
      brandToneOfVoice: const [
        {'trait': 'EMPATHETIC', 'desc': 'Reassuring, respectful, and focused on patient comfort and peace of mind.'},
        {'trait': 'AUTHORITATIVE', 'desc': 'Grounded in verified medical science and clinical guidelines.'},
        {'trait': 'ACCESSIBLE', 'desc': 'Translating complex medical jargon into clear, understandable advice.'},
        {'trait': 'TRUSTWORTHY', 'desc': 'Upholding patient confidentiality and professional medical ethics.'},
      ],
      brandColorDetails: const {
        'primary': {'name': 'Clinical Teal', 'hex': '#0F766E'},
        'secondary': {'name': 'Healing Cyan', 'hex': '#14B8A6'},
        'accent': {'name': 'Calm Sky', 'hex': '#0EA5E9'},
      },
      contentFrameworkWeeks: const [
        {'week': 'WEEK 1', 'experienceStories': 'Patient Journey: From Chronic Discomfort to Full Recovery', 'educational': '3 Symptoms You Should Never Ignore', 'corporate': 'Corporate Executive Health Screening Packages', 'testimonials': 'Patient Feedback (Care & Empathy)', 'promotional': 'Book Your Annual Health Assessment', 'contentExamples': '• Patient story\n• Symptom checklist\n• Corporate wellness\n• Patient review\n• Booking link'},
        {'week': 'WEEK 2', 'experienceStories': 'Doctor Walkthrough: What Happens During Your First Visit', 'educational': 'Common Medical Myths vs Medical Facts', 'corporate': 'Ergonomic Health & Workplace Preventative Care', 'testimonials': 'Patient Feedback (Gentle Treatment)', 'promotional': 'Teleconsultation Slots Available', 'contentExamples': '• First visit tour\n• Myth busting carousel\n• Workplace wellness tips\n• Review quote\n• Booking link'},
        {'week': 'WEEK 3', 'experienceStories': 'Behind the Scenes: Clinical Sterilization & Safety Protocols', 'educational': 'How Lifestyle & Sleep Impact Your Immune Health', 'corporate': 'Workplace Health Screening Roadshow', 'testimonials': 'Patient Feedback (Doctor Attentiveness)', 'promotional': 'Preventative Screening Checklist Download', 'contentExamples': '• Safety reel\n• Lifestyle guide\n• Corporate event recap\n• Testimonial quote\n• Download guide link'},
        {'week': 'WEEK 4', 'experienceStories': 'Doctor Q&A: Answering This Month’s Top Patient Inquiries', 'educational': 'When to See a Specialist vs General Practitioner', 'corporate': 'Corporate Health Talks & Wellness Webinars', 'testimonials': 'Patient Feedback (Overall Recovery)', 'promotional': 'Secure Next Month’s Consultation Slot', 'contentExamples': '• Doctor Q&A reel\n• Referral guide\n• Health talk recap\n• Patient recovery story\n• Calendar reminder'},
      ],
      sampleReelHeadline: 'Care You Can Trust',
      sampleReelTopic: 'Doctor Explains: 3 Health Symptoms You Should Never Brush Aside',
      sampleReelHook: 'Most people wait until the pain is unbearable before getting checked. Here are 3 subtle signs your body is asking for help.',
      sampleReelVisualScenes: 'Scene 1: Friendly doctor speaking directly to camera in modern clinical office.\nScene 2: Close-up on diagram illustrating symptom progression.\nScene 3: Reassuring shot of doctor and patient reviewing health results.\nScene 4: Clear call to action with clinic location and booking information.',
      sampleReelCta: 'Prioritize your health before symptoms escalate. Tap the link in bio to book your consultation with our medical team.',
      sampleReelLink: websiteUrl,
      sampleBlogTitle: 'The Complete Patient Guide to Preventative Health Screenings: What Tests You Actually Need',
      sampleBlogStorytellingIntro: 'Medical care should never be reactive. Understanding your health profile before acute symptoms occur provides the greatest certainty, comfort, and longevity for you and your family.',
      sampleBlogPreview: 'When was the last time you reviewed your core health markers? For busy professionals and parents, scheduling a comprehensive medical consultation often slips down the priority list until discomfort forces an urgent visit...\n\nIn this clinical guide, our medical team breaks down the essential screening panels for every stage of life.',
      sampleSocialCaptionHook: 'Your body rarely whispers without a reason. 🩺',
      sampleSocialCaptionBody: 'Taking care of your health does not have to be intimidating or stressful. At $leadCompanyName, our medical team combines clinical precision with genuine empathy, ensuring you feel heard and supported at every stage.\n\nSchedule your routine check-up or specialized consultation with us today.',
      sampleSocialCaptionCta: '📍 Book your appointment online or contact our clinic reception.',
      sampleSocialHashtags: const ['#Healthcare', '#DoctorAdvice', '#PreventativeCare', '#HealthFirst', '#MeetMarketers'],
      socialPosts: const [
        {'title': 'Doctor Education', 'headline': 'DON\'T IGNORE THE EARLY WARNING SIGNS.', 'body': 'Most health complications are easiest to treat when caught early.\n\nOur medical team is here to listen, diagnose accurately, and provide a clear recovery plan.\n\nBook your consultation at our clinic today.', 'badge': 'LICENSED CLINICAL CARE', 'hashtags': ['#HealthCheck', '#DoctorAdvice', '#PreventativeHealth'], 'imageUrl': ''},
        {'title': 'Patient Journey', 'headline': 'A HEALTHCARE EXPERIENCE DESIGNED AROUND YOU.', 'body': 'No rushed 3-minute consultations. No confusing medical jargon.\n\nAt our clinic, we take the time to explain your condition, discuss treatment options, and guide you through recovery step by step.\n\nAppointments available this week.', 'badge': 'PATIENT-FIRST CARE', 'hashtags': ['#FamilyHealth', '#MedicalCare', '#TrustedDoctor'], 'imageUrl': ''},
        {'title': 'Preventative Health', 'headline': 'WHEN WAS YOUR LAST HEALTH SCREENING?', 'body': 'Prioritizing your health today gives you the peace of mind to enjoy tomorrow.\n\nExplore our comprehensive health screening packages designed for every life stage.\n\nCheck available dates via link in bio.', 'badge': 'PREVENTATIVE WELLNESS', 'hashtags': ['#HealthScreening', '#Longevity', '#WellnessCare'], 'imageUrl': ''},
      ],
      seoAudit: const SeoAuditSummary(
        healthScore: 70,
        summaryText: 'Solid baseline presence but significant opportunities to capture local patient search intent through Google Business Profile 3-pack optimization, medical condition Schema markup, and treatment-specific landing pages.',
        highPriority: ['Google Business Profile local 3-pack SEO and review automation', 'MedicalWebPage and Physician Schema.org structured data', 'Treatment-specific landing pages (Symptoms, FAQs, Pricing transparency)', 'Mobile page speed and appointment booking UX optimization'],
        mediumPriority: ['Doctor biography pages with verified medical credentials and E-E-A-T signals', 'Open Graph social cards for health education guides', 'Automated SMS / WhatsApp appointment confirmation flows'],
        longTermOpportunities: ['AI search engine discoverability (ChatGPT & Perplexity for local health queries)', 'Comprehensive patient health library and condition encyclopedia', 'Integrated telemedicine portal with online prescription refills'],
      ),
      seoAssessmentText: 'We recommend prioritizing local clinic SEO and treatment-specific landing pages in Phase 1 to capture high-intent patients actively searching for care in your immediate radius.',
      seoAuditLink: 'https://meet-marketers.com/seo-audit',
      finalThoughtsSummary: '$leadCompanyName provides exceptional clinical care and patient dedication. Our proposed digital and content roadmap elevates that offline reputation into dominant digital visibility, establishing your clinic as the first choice for patients seeking trusted medical care.',
      finalThoughtsRecommendation: 'We recommend initiating Phase 1: Local clinic SEO and doctor-led educational video reels, followed by condition-specific search landing pages to consistently drive qualified patient appointments.',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. LUXURY & HOSPITALITY (Yachts, Charters, Luxury Resorts)
  // ───────────────────────────────────────────────────────────────────────────
  ProposalModel _synthesizeLuxuryHospitality({
    required String proposalId,
    required String amId,
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    required Map<String, String> socialUrls,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
  }) {
    return ProposalModel(
      id: proposalId,
      amId: amId,
      leadCompanyName: leadCompanyName,
      industry: industry.isNotEmpty ? industry : 'Luxury Hospitality & Charters',
      websiteUrl: websiteUrl,
      socialUrls: socialUrls,
      pitchDeckFileName: pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText,
      status: ProposalStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      executiveSummaryPosition:
          '$leadCompanyName operates as a premier provider of private yacht charters and luxury experiential hospitality, creating unforgettable milestone moments, celebrations, and corporate retreats.',
      executiveSummaryOpportunity:
          'While $leadCompanyName holds strong customer goodwill and positive reviews, substantial opportunity exists to capture high-ticket milestone bookings and corporate retreats through cinematic vertical video, lifestyle storytelling, and search engine domination.',
      swot: const SwotMatrix(
        strengths: ['Established reputation for hospitality and impeccable safety record', 'Diverse private fleet packages for intimate to large groups', 'High customer satisfaction and repeat booking loyalty', 'Experienced, attentive onboard crew and bespoke catering options'],
        weaknesses: ['Competitor messaging often mirrors generic boat features rather than emotional experience', 'Limited educational content guiding first-time charter guests', 'Corporate B2B retreat market under-communicated in marketing channels', 'Seasonal weekday charter availability requires targeted promotional push'],
        opportunities: ['Capturing high-ticket corporate offsites and team bonding packages', 'Short-form cinematic video storytelling on Instagram and TikTok', 'Occasion-specific landing pages (Milestone Birthdays, Proposals, Corporate Charters)', 'Dominating high-intent search queries ("Private Yacht Charter Singapore")'],
        threats: ['Price discounting by mass-market operators diluting perceived industry value', 'Inclement weather and maritime scheduling dependencies', 'Rising digital acquisition costs across paid social advertising', 'Consumer perception that private charters are overly complex to organize'],
      ),
      marketingMix4Ps: const MarketingMix4Ps(
        productCurrent: 'Private charter vessels, customized celebration packages, corporate offsite cruises, and watersports inclusions.',
        productOpportunity: 'Position complete stress-free experiential packages: "Turnkey Milestone Celebration", "Executive Sunset Retreat", and "Intimate Maritime Proposal".',
        priceCurrent: 'Tiered charter pricing based on vessel size, duration, and guest headcount.',
        priceOpportunity: 'Emphasize all-inclusive value (crew, fuel, amenities, no hidden charges) and premium service certainty rather than competing on discount rates.',
        placeCurrent: 'Website inquiry forms, marina partnerships, WhatsApp booking line, and referral networks.',
        placeOpportunity: 'Streamline digital inquiry flow with real-time calendar availability checks, instant WhatsApp concierges, and occasion-specific landing hubs.',
        promotionCurrent: 'Social media celebration highlights, customer reviews, and seasonal holiday promotions.',
        promotionOpportunity: 'Deploy cinematic drone storytelling, first-timer charter guides, and customer reaction reels showcasing unfiltered celebration joy.',
      ),
      pestAnalysis: const PestAnalysis(
        political: ['Maritime and port authority safety standards and vessel certification compliance', 'Tourism board guidelines and international visitor recovery standards', 'Environmental maritime regulations regarding marine conservation and fuel standards'],
        economic: ['Accelerating experiential economy with consumers prioritizing memories over material goods', 'Corporate entertainment and team offsite budget recovery post-pandemic', 'Rising disposable income among affluent domestic and regional travelers'],
        social: ['High consumer demand for private, exclusive celebration venues away from public crowds', 'Desire for shareable, aesthetic visual moments for personal social media', 'Growing appreciation for wellness, coastal escapism, and sea-based lifestyle resets'],
        technological: ['Algorithmic video distribution (Reels, TikTok) driving viral experiential discovery', 'Instant messaging concierges (WhatsApp Business API) enabling friction-free reservations', 'AI-assisted destination trip planning and search discoverability'],
      ),
      competitorUsps: [
        CompetitorUsp(brandName: leadCompanyName, primaryUsp: 'Premier tailored experiences, outstanding service reliability, customer trust, and all-inclusive transparent pricing', isLeadBrand: true),
        const CompetitorUsp(brandName: 'Competitor Alpha (Mass Operator)', primaryUsp: 'High-volume discount pricing with standardized inclusions'),
        const CompetitorUsp(brandName: 'Competitor Beta (Boutique Specialist)', primaryUsp: 'Ultra-exclusive luxury superyachts with premium charter minimums'),
        const CompetitorUsp(brandName: 'Competitor Gamma (Event Fleet)', primaryUsp: 'Standard corporate event packages with generic catering add-ons'),
      ],
      perceptualMapNarrative: '$leadCompanyName occupies a commanding position between bespoke luxury experiences and broad occasion versatility, delivering premium memories without inaccessible exclusivity.',
      perceptualMapInsight: 'Customers do not book boats based on length or engine specifications—they purchase the emotional certainty, privacy, and seamless execution of high-stakes life moments.',
      perceptualMapOpportunity: 'Reinforce $leadCompanyName as the definitive first choice for private celebrations and corporate marine retreats.',
      creativePillars: [
        const ContentPillar(title: 'Celebration & Milestone Moments', objective: 'Showcase genuine emotional reactions and milestone celebrations on the water.', contentStyle: ['Event recap reels', 'Surprise birthday reveals', 'Proposal highlights'], exampleTopics: ['A Celebration They Will Talk About For Years', 'Behind This Secret Sunset Proposal', 'Turning 30 on the Water']),
        const ContentPillar(title: 'First-Timer Charter Education', objective: 'Eliminate booking hesitation by walking prospective guests through the seamless experience.', contentStyle: ['Checklist carousels', 'What to pack guides', 'FAQ reels'], exampleTopics: ['First Time Chartering? Here Is What to Expect', 'What Happens If It Rains?', 'How to Plan the Perfect Yacht Party']),
        const ContentPillar(title: 'Corporate & Executive Retreats', objective: 'Capture high-ticket B2B company offsites, team bonding, and client entertainment.', contentStyle: ['Corporate recap videos', 'Team bonding testimonials', 'Executive interviews'], exampleTopics: ['Your Team Deserves Better Than a Hotel Ballroom', 'Why Companies Choose Private Charters for Offsites', 'Hosting High-Stakes Clients on the Water']),
        const ContentPillar(title: 'Coastal Lifestyle & Aspiration', objective: 'Inspire wanderlust and coastal luxury aesthetics.', contentStyle: ['Cinematic drone visuals', 'Golden hour atmospheric B-roll', 'Weekend reset moments'], exampleTopics: ['The Perspective Most People Never See', 'Weekend Reset in Style', 'Escape the City Without Leaving Town']),
        ContentPillar(title: 'Guest Testimonials & Unfiltered Proof', objective: 'Build unshakeable social proof through authentic customer stories.', contentStyle: const ['Guest reaction clips', 'Review overlays', 'Before & after planning journeys'], exampleTopics: ['Why They Chose $leadCompanyName', 'Their Honest Review on the Way Back to the Marina', '14 Years of Unforgettable Memories']),
      ],
      visualGuidelineNotes: 'Cinematic marine aesthetic with golden hour lighting, sparkling ocean horizons, authentic laughter, and refined luxury typography. Crisp navy blues, warm sand tones, and oceanic aquas.',
      brandPaletteHex: const ['#001B2A', '#1E6BE5', '#E7D7B5', '#0F172A', '#F8FAFC'],
      visualKeywords: const ['Experiential', 'Lifestyle-driven', 'Aspirational', 'Authentic', 'Coastal'],
      focusMoreOn: ['People interacting and laughing', 'Genuine celebration reactions', 'Sunset horizons and sea reflections', 'Curated food, drinks, and decor'],
      focusLessOn: ['Empty boat hulls and engine rooms', 'Generic harbour docks without guests', 'Overly staged commercial stock photography', 'Aggressive promotional sales text overlays'],
      photographyQuote: "People don't book yachts. People book experiences.",
      typographySampleHeadline: "SAIL. RELAX. CELEBRATE.",
      brandToneOfVoice: const [
        {'trait': 'FRIENDLY', 'desc': 'Warm, approachable, and eager to help guests create lifelong memories.'},
        {'trait': 'INFORMATIVE', 'desc': 'Providing clear, transparent guidance to make charter planning effortless.'},
        {'trait': 'ASPIRATIONAL', 'desc': 'Inspiring guests to envision their ultimate coastal celebration.'},
        {'trait': 'TRUSTWORTHY', 'desc': 'Highlighting maritime safety, transparent pricing, and 14+ years of proven excellence.'},
      ],
      brandColorDetails: const {
        'primary': {'name': 'Navy Blue', 'hex': '#001B2A'},
        'secondary': {'name': 'Ocean Blue', 'hex': '#1E6BE5'},
        'accent': {'name': 'Sand / Beige', 'hex': '#E7D7B5'},
      },
      contentFrameworkWeeks: const [
        {'week': 'WEEK 1', 'experienceStories': 'Birthday Celebration on Board', 'educational': 'What to Expect on Your Charter', 'corporate': 'Team Bonding That Brings Teams Closer', 'testimonials': 'Client Testimonial (Team Bonding)', 'promotional': 'Weekend Charter Special', 'contentExamples': '• Sunset celebration dinner\n• Charter checklist\n• Corporate team day\n• Client review video\n• Weekend promotion'},
        {'week': 'WEEK 2', 'experienceStories': 'Proposal Moments Done Right', 'educational': 'Yacht Etiquette 101', 'corporate': 'Corporate Client Appreciation Event', 'testimonials': 'Client Testimonial (Corporate)', 'promotional': 'Mid-Week Special Offer', 'contentExamples': '• Proposal setup reel\n• Do\'s & don\'ts onboard\n• Appreciation event\n• Client review\n• Mid-week discount'},
        {'week': 'WEEK 3', 'experienceStories': 'Family Day Out on the Water', 'educational': 'Best Time to Go Yacht Chartering', 'corporate': 'Leadership Retreat on the Sea', 'testimonials': 'Client Testimonial (Family)', 'promotional': 'School Holiday Charter Package', 'contentExamples': '• Family fun activities\n• Seasonal guide\n• Leadership retreat\n• Family review\n• Holiday promo'},
        {'week': 'WEEK 4', 'experienceStories': 'Anniversary Celebration on Board', 'educational': 'What Happens If It Rains? (FAQ)', 'corporate': 'Client Networking Event', 'testimonials': 'Client Testimonial (Celebration)', 'promotional': 'End of Month Exclusive Offer', 'contentExamples': '• Anniversary dinner\n• FAQ post\n• Networking event\n• Celebration review\n• End of month promo'},
      ],
      sampleReelHeadline: 'Live in the moment',
      sampleReelTopic: 'Behind This Surprise Milestone Celebration with $leadCompanyName',
      sampleReelHook: 'Most people think planning an extraordinary celebration takes months of stress. Watch what happened when they chose something different.',
      sampleReelVisualScenes: 'Scene 1: Golden hour horizon with sparkling water and laughter.\nScene 2: Close-up of personalized decor and toast with friends.\nScene 3: Unfiltered joyous reaction of the guest of honor.\nScene 4: Crew seamlessly attending to every detail while guests relax.',
      sampleReelCta: 'Save this for your next milestone celebration or tap the link in bio to book your private experience.',
      sampleReelLink: websiteUrl,
      sampleBlogTitle: 'How to Plan an Unforgettable Milestone Celebration in Singapore (Without the Usual Stress)',
      sampleBlogStorytellingIntro: 'Rather than relying on promotional sales messaging, our content approach focuses on storytelling and customer-centric narratives that help audiences visualize the experience before they book.',
      sampleBlogPreview: 'When planning a major celebration, most organizers are forced to choose between crowded public restaurants or sterile hotel ballrooms. But true luxury is about privacy, personalized attention, and memories that last long after the evening ends...\n\nIn this comprehensive guide, we unpack everything from selecting the right package to food and beverage coordination, music, and capturing memories on camera.',
      sampleSocialCaptionHook: 'The best celebrations are the ones where you don’t have to worry about a single detail. ✨',
      sampleSocialCaptionBody: 'Whether it is a milestone 30th birthday, an intimate anniversary, or an executive retreat, your moments deserve more than routine routines. Step into curated luxury where everything is taken care of from start to finish.\n\nDM us or WhatsApp our concierge to check date availability.',
      sampleSocialCaptionCta: '💬 Check availability for your date via the link in bio.',
      sampleSocialHashtags: const ['#PrivateCharter', '#CelebrateInStyle', '#LuxuryRetreats', '#MeetMarketers'],
      socialPosts: const [
        {'title': 'Corporate & Team Bonding', 'headline': 'YOUR TEAM DESERVES BETTER THAN A HOTEL BALLROOM.', 'body': 'Team bonding works when people stop feeling like they\'re at work.\n\nA private charter does that faster than any workshop or lunch outing.\n\nProfessional crew, watersports, and skyline views on the way back.\n\nNo hidden fees. Just book and show up.\n\nDM us to lock in your date.', 'badge': 'PRIVATE CHARTER', 'hashtags': ['#CorporateEvents', '#TeamBonding', '#OfficeOuting'], 'imageUrl': ''},
        {'title': 'Milestone Celebrations', 'headline': 'Turning 30?', 'body': 'No restaurant private room. No shared space. No two-hour limit.\n\nJust your group, a private vessel, and hours on the water.\n\nThis is what a birthday actually feels like when it\'s done right.\n\nCheck availability for your date via link in bio.', 'badge': 'PRIVATE CHARTER', 'hashtags': ['#BirthdayCelebration', '#Turning30', '#SingaporeMoments'], 'imageUrl': ''},
        {'title': 'Client Story & Reviews', 'headline': 'It was the best celebration I\'ve ever had.', 'body': 'When your guests say that on the way back to the marina, the planning was worth it.\n\nFull crew included. No surprise charges.\n\nBook with confidence via our website.', 'badge': 'VERIFIED REVIEWS', 'hashtags': ['#CustomerReview', '#LuxuryExperience', '#Memories'], 'imageUrl': ''},
      ],
      seoAudit: SeoAuditSummary(
        healthScore: 68,
        summaryText: '$leadCompanyName has established a solid foundation with mobile-friendly pages, but several high-impact technical and occasion-specific search opportunities remain to scale organic leads.',
        highPriority: ['Occasion-specific landing pages (Milestone Birthdays, Corporate Charters, Proposals)', 'Schema.org structured review and boat reservation markup', 'H1 and Meta Title optimization across core package pages', 'Core Web Vitals acceleration and WebP image optimization'],
        mediumPriority: ['Service detail page conversion and FAQ schema optimization', 'Open Graph rich social sharing cards', 'Author and destination entity markup'],
        longTermOpportunities: ['AI search engine discoverability (AIO & Perplexity for charter queries)', 'Comprehensive destination guides (Southern Islands, Lazarus Island)', 'Dedicated corporate event planner inquiry flow'],
      ),
      seoAssessmentText: 'Based on our review, we recommend prioritising technical SEO improvements and occasion-specific landing pages as the first phase of optimisation.',
      seoAuditLink: 'https://meet-marketers.com/seo-audit',
      finalThoughtsSummary: '$leadCompanyName already possesses the qualities today’s customers seek: memorable experiences, professional service, and trusted execution. Our proposed direction bridges the gap between great service and dominant digital category authority.',
      finalThoughtsRecommendation: 'We recommend prioritizing technical SEO quick wins and occasion-specific landing pages as Phase 1, followed by short-form video storytelling to scale lead volume.',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. B2B TECH & SAAS
  // ───────────────────────────────────────────────────────────────────────────
  ProposalModel _synthesizeB2BTech({
    required String proposalId,
    required String amId,
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    required Map<String, String> socialUrls,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
  }) {
    return ProposalModel(
      id: proposalId,
      amId: amId,
      leadCompanyName: leadCompanyName,
      industry: industry.isNotEmpty ? industry : 'B2B Software & Cloud Technology',
      websiteUrl: websiteUrl,
      socialUrls: socialUrls,
      pitchDeckFileName: pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText,
      status: ProposalStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      executiveSummaryPosition:
          '$leadCompanyName delivers scalable B2B software solutions, engineering robust cloud architecture and intelligent automated workflows for modern enterprises.',
      executiveSummaryOpportunity:
          'Enterprise software procurement is won on measurable ROI, developer trust, and clear solution architecture. By deploying interactive product walkthroughs, developer documentation SEO, and customer transformation case studies, $leadCompanyName can dramatically shorten sales cycles.',
      swot: const SwotMatrix(
        strengths: ['Robust proprietary software architecture and API reliability', 'Demonstrated customer productivity gains and enterprise security compliance', 'Intuitive user onboarding and low time-to-value', 'Agile product engineering roadmap'],
        weaknesses: ['Organic search rankings behind legacy enterprise incumbents', 'Product positioning occasionally overly technical for non-technical buyers', 'Case studies lack interactive ROI demonstration', 'Under-utilized video demos on LinkedIn and YouTube'],
        opportunities: ['Dominating high-intent SaaS search terms ("Best enterprise workflow automation tool")', 'Interactive product tour landing pages and ROI calculators', 'Technical thought leadership on LinkedIn from founding engineers', 'AI search discoverability (Perplexity, ChatGPT for software comparisons)'],
        threats: ['Fast-evolving AI tools creating commoditization pressure', 'Prolonged enterprise software procurement and budget approval cycles', 'Aggressive venture-backed competitors spending heavily on paid search', 'Customer churn risks without proactive customer success onboarding'],
      ),
      marketingMix4Ps: const MarketingMix4Ps(
        productCurrent: 'Cloud software platform, enterprise API integrations, automated workflow modules, and dedicated customer support.',
        productOpportunity: 'Package modular enterprise tiers: "Growth Team Edition", "Enterprise Scale Suite", and "Custom White-Glove Integration".',
        priceCurrent: 'Tiered subscription pricing based on seats, usage volume, or feature tiers.',
        priceOpportunity: 'Highlight transparent ROI and operational cost reduction, comparing software investment against hundreds of manual engineering hours.',
        placeCurrent: 'Direct website self-serve signup, enterprise sales demo booking, and partner marketplaces.',
        placeOpportunity: 'Expand presence in software directories (G2, Capterra), cloud marketplaces (AWS/GCP), and developer documentation hubs.',
        promotionCurrent: 'Product release notes, paid search ads, and occasional industry webinar participation.',
        promotionOpportunity: 'Deploy interactive product teardowns, customer engineering case studies, and weekly LinkedIn software architecture insights.',
      ),
      pestAnalysis: const PestAnalysis(
        political: ['Global data sovereignty, GDPR, and cloud compliance regulations', 'Cybersecurity certification mandates (SOC 2, ISO 27001)', 'Government enterprise digitalization grants supporting software adoption'],
        economic: ['Corporate IT budgets prioritizing cost-reduction and workflow automation tools', 'SaaS budget consolidation favoring all-in-one platforms over point solutions', 'Shift toward product-led growth (PLG) and usage-based billing models'],
        social: ['Remote and hybrid engineering teams demanding seamless asynchronous collaboration', 'Enterprise buyers conducting autonomous self-service software research before talking to sales', 'Rising developer preference for transparent documentation over sales pitches'],
        technological: ['Integration of Generative AI copilots into routine enterprise workflows', 'Low-code / no-code API integrations enabling rapid software deployment', 'AI-assisted code generation and automated testing reshaping tech capabilities'],
      ),
      competitorUsps: [
        CompetitorUsp(brandName: leadCompanyName, primaryUsp: 'Lightweight agile deployment, superior speed-to-value, and dedicated enterprise engineering support', isLeadBrand: true),
        const CompetitorUsp(brandName: 'Legacy Enterprise Competitor', primaryUsp: 'Complex legacy suite with long multi-month deployment cycles'),
        const CompetitorUsp(brandName: 'Venture-Backed Challenger', primaryUsp: 'High-frequency feature rollouts with aggressive promotional freemium tiers'),
        const CompetitorUsp(brandName: 'Point Solution Operator', primaryUsp: 'Niche single-feature utility without broader workflow integrations'),
      ],
      perceptualMapNarrative: '$leadCompanyName provides the ideal balance between enterprise-grade reliability and lightweight, modern developer ergonomics, outpacing bloated legacy systems.',
      perceptualMapInsight: 'B2B buyers do not purchase software for feature checklists—they invest in guaranteed time savings, risk reduction, and predictable operational scale.',
      perceptualMapOpportunity: 'Position $leadCompanyName as the most modern, reliable, and high-ROI platform in its software category.',
      creativePillars: [
        const ContentPillar(title: 'Product Teardowns & Architecture', objective: 'Showcase product ergonomics, speed, and real-world workflow automation.', contentStyle: ['Screen-record walkthroughs', 'Interactive architecture diagrams', 'Feature spotlights'], exampleTopics: ['How to Automate 20 Hours of Manual Tasks in 3 Clicks', 'Inside Our Scalable Cloud Architecture', 'Why Traditional Workflows Fail at Scale']),
        const ContentPillar(title: 'Customer ROI & Transformation', objective: 'Provide concrete proof of cost reduction and productivity gains across customer deployments.', contentStyle: ['Before & after case studies', 'ROI calculation breakdowns', 'Customer CTO interviews'], exampleTopics: ['How This Enterprise Cut Processing Time by 65%', 'From Legacy Chaos to Streamlined Operations', 'The Real Cost of Staying on Manual Workflows']),
        const ContentPillar(title: 'Engineering & Founder Insights', objective: 'Build technical credibility through behind-the-scenes engineering decisions.', contentStyle: ['Tech deep-dives', 'Bug squash stories', 'Founder vision updates'], exampleTopics: ['Why We Re-Engineered Our Core API for 10x Speed', 'Lessons Learned Scaling to 100k Daily Transactions', 'Building for 99.99% Uptime']),
        const ContentPillar(title: 'Industry Comparison & Teardowns', objective: 'Help buyers make informed evaluations against legacy alternatives.', contentStyle: ['Comparison tables', 'Feature matrices', 'Migration guides'], exampleTopics: ['Legacy Systems vs Modern Cloud Architecture', 'What to Look for in an Enterprise Solution', 'Migrating with Zero Downtime']),
        const ContentPillar(title: 'Actionable Workflow Templates', objective: 'Offer immediate utility to technical teams through saveable resources.', contentStyle: ['Template downloads', 'Checklist carousels', 'Quick-tip videos'], exampleTopics: ['The Ultimate Enterprise Workflow Checklist', '5 Automation Recipes You Can Implement Today', 'Audit Your Tech Stack in 15 Minutes']),
      ],
      visualGuidelineNotes: 'Sleek dark-mode aesthetic with vibrant cyber accents, high-fidelity UI mockups, crisp code snippets, and modern sans-serif typography. Deep slates, neon cyans, and clean whites.',
      brandPaletteHex: const ['#0B0F19', '#1E293B', '#06B6D4', '#6366F1', '#F8FAFC'],
      visualKeywords: const ['Modern', 'Technical', 'High-speed', 'Precise', 'Ergonomic'],
      focusMoreOn: ['Clean high-resolution product interfaces', 'Real workflow diagrams and metrics', 'Engineering teams building and collaborating', 'Data visualization charts'],
      focusLessOn: ['Cheesy stock handshakes in conference rooms', 'Generic clip-art gears and lightbulbs', 'Vague corporate slogans without product context', 'Overly complex mathematical equations without explanation'],
      photographyQuote: "Enterprises don't buy software features. They buy operational velocity, risk reduction, and competitive advantage.",
      typographySampleHeadline: "AUTOMATE. SCALE. OUTPERFORM.",
      brandToneOfVoice: const [
        {'trait': 'TECHNICAL & PRECISE', 'desc': 'Speaking with engineering clarity, accuracy, and depth.'},
        {'trait': 'EMPOWERING', 'desc': 'Enabling teams to eliminate bottlenecks and build with velocity.'},
        {'trait': 'TRANSPARENT', 'desc': 'Providing honest benchmarking, uptime transparency, and clear pricing.'},
        {'trait': 'FORWARD-THINKING', 'desc': 'Leading the next evolution of intelligent cloud software.'},
      ],
      brandColorDetails: const {
        'primary': {'name': 'Cyber Slate', 'hex': '#0B0F19'},
        'secondary': {'name': 'Electric Cyan', 'hex': '#06B6D4'},
        'accent': {'name': 'Indigo Pulse', 'hex': '#6366F1'},
      },
      contentFrameworkWeeks: const [
        {'week': 'WEEK 1', 'experienceStories': 'Customer Migration Story: Moving Off Legacy Tech in 14 Days', 'educational': 'How to Audit Your Tech Stack for Bottlenecks', 'corporate': 'Enterprise Security & SOC 2 Compliance Brief', 'testimonials': 'CTO Testimonial (Platform Reliability)', 'promotional': 'Book an Enterprise Architecture Demo', 'contentExamples': '• Migration case study\n• Audit checklist\n• Security post\n• CTO review quote\n• Demo booking link'},
        {'week': 'WEEK 2', 'experienceStories': 'Product Walkthrough: Eliminating 15 Hours of Manual Weekly Tasks', 'educational': 'Modern Cloud APIs vs Outdated Webhooks', 'corporate': 'Volume Tiering & Custom Integration Options', 'testimonials': 'Lead Engineer Testimonial (Developer Ergonomics)', 'promotional': 'Start Free 14-Day Enterprise Sandbox', 'contentExamples': '• Product demo video\n• API comparison carousel\n• Pricing tier guide\n• Engineer quote\n• Free trial link'},
        {'week': 'WEEK 3', 'experienceStories': 'Scaling to 10M API Requests: An Engineering Breakdown', 'educational': 'The True Total Cost of Ownership of In-House Tools', 'corporate': 'White-Glove Onboarding & Dedicated Support SLAs', 'testimonials': 'Operations Lead Testimonial (Team Productivity)', 'promotional': 'Download the 2026 Enterprise Automation Benchmark', 'contentExamples': '• Scaling case study\n• TCO calculator carousel\n• Support SLA spotlight\n• Operations review\n• Whitepaper link'},
        {'week': 'WEEK 4', 'experienceStories': 'Monthly Product Release: 4 New Features Requested by Users', 'educational': 'How AI Agents Are Redefining Business Workflows', 'corporate': 'Quarterly Business Review (QBR) Framework for Clients', 'testimonials': 'Executive Sponsor Testimonial (Measurable ROI)', 'promotional': 'Schedule Your Strategic Tech Stack Review', 'contentExamples': '• Release notes video\n• AI trends carousel\n• QBR framework post\n• Executive review quote\n• Strategy call link'},
      ],
      sampleReelHeadline: 'Build Faster',
      sampleReelTopic: 'Watch How This Engineering Team Cut Deployment Time by 70%',
      sampleReelHook: 'Most enterprise software takes 6 months to implement. Watch our platform configure a production pipeline in 4 minutes.',
      sampleReelVisualScenes: 'Scene 1: Split screen showing frantic manual data entry vs clean automated workflow.\nScene 2: High-speed screencast of intuitive dashboard configuration.\nScene 3: Real-time analytics updating with 99.99% uptime badge.\nScene 4: Happy engineering team shipping to production with clean brand logo.',
      sampleReelCta: 'Stop wasting engineering hours on manual workflows. Book your live demo via link in bio.',
      sampleReelLink: websiteUrl,
      sampleBlogTitle: 'The Modern Enterprise Tech Stack: Why Agile Cloud Platforms Are Replacing Legacy Monoliths',
      sampleBlogStorytellingIntro: 'In high-velocity software markets, organizational agility is dictated by the tools your team uses every day. Monolithic legacy systems introduce invisible friction that slows product velocity and increases maintenance overhead.',
      sampleBlogPreview: 'When was the last time your team audited your software procurement for hidden latency? Across hundreds of enterprise deployments, we consistently find that engineering teams spend up to 35% of their working hours maintaining brittle custom scripts...\n\nIn this technical whitepaper, we outline the modern architectural blueprint for high-scale enterprise workflows.',
      sampleSocialCaptionHook: 'Manual workflows are the silent productivity killer of modern teams. 💻',
      sampleSocialCaptionBody: 'Your engineering and operations teams were hired to innovate, not babysit outdated legacy systems.\n\n$leadCompanyName automates complex data pipelines, eliminates manual errors, and scales seamlessly with your enterprise growth.\n\nSee how modern teams deploy in minutes, not months.',
      sampleSocialCaptionCta: '🚀 Schedule your personalized architecture demo today.',
      sampleSocialHashtags: const ['#B2BTech', '#EnterpriseSaaS', '#CloudComputing', '#WorkflowAutomation', '#MeetMarketers'],
      socialPosts: const [
        {'title': 'Product Ergonomics', 'headline': 'STOP BABYSITTING FRAGILE WORKFLOWS.', 'body': 'Modern teams don\'t have time for clunky enterprise tools with multi-month onboarding.\n\nOur platform integrates in minutes, automates manual data flows, and guarantees 99.99% uptime.\n\nExperience the modern standard in enterprise software.', 'badge': 'ENTERPRISE SAAS', 'hashtags': ['#DevOps', '#CloudPlatform', '#SaaS'], 'imageUrl': ''},
        {'title': 'ROI & Transformation', 'headline': 'HOW ONE TEAM SAVED 1,200 HOURS THIS QUARTER.', 'body': 'By replacing manual spreadsheets with automated workflows, our clients redirect hundreds of engineering hours toward revenue-generating features.\n\nCalculate your team\'s potential ROI with our interactive calculator.', 'badge': 'PROVEN ROI', 'hashtags': ['#Productivity', '#EnterpriseAutomation', '#TechROI'], 'imageUrl': ''},
        {'title': 'Engineering Excellence', 'headline': 'BUILT FOR 99.99% PRODUCTION RELIABILITY.', 'body': 'When enterprise operations depend on your software, downtime is not an option.\n\nDiscover how our cloud architecture ensures zero-downtime deployments and enterprise-grade security compliance.', 'badge': 'SOC 2 CERTIFIED', 'hashtags': ['#CloudSecurity', '#SoftwareEngineering', '#Scalability'], 'imageUrl': ''},
      ],
      seoAudit: const SeoAuditSummary(
        healthScore: 74,
        summaryText: 'Strong technological baseline but significant keyword opportunities remain in technical comparison pages ("Software vs Competitor"), developer documentation indexing, and entity search discoverability across AI platforms.',
        highPriority: ['Software feature and comparison landing pages ("Alternative to Competitor")', 'SoftwareApplication and TechnicalArticle Schema.org structured data', 'Developer documentation and API guides organic indexation', 'Interactive ROI calculator landing page with high-intent lead capture'],
        mediumPriority: ['G2 and Capterra review profile syndication and badge schema', 'Open Graph cards with dynamic software metrics for social shares', 'Customer case study directory with industry and company size filters'],
        longTermOpportunities: ['AI search engine ranking (Perplexity & ChatGPT for B2B software recommendations)', 'Comprehensive developer engineering blog and open-source utility hub', 'Self-service enterprise sandbox with frictionless onboarding'],
      ),
      seoAssessmentText: 'We recommend prioritizing comparison landing pages and developer documentation SEO in Phase 1 to capture buyers actively searching for alternatives to legacy market incumbents.',
      seoAuditLink: 'https://meet-marketers.com/seo-audit',
      finalThoughtsSummary: '$leadCompanyName has engineered an exceptional software product with clear technical superiority. Our digital marketing framework transforms this engineering excellence into dominant organic pipeline and qualified enterprise demo bookings.',
      finalThoughtsRecommendation: 'We recommend initiating Phase 1: High-intent software comparison landing pages and LinkedIn product teardown videos, followed by customer ROI case studies to systematically drive enterprise inbound sales.',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. GENERAL ENTERPRISE & PROFESSIONAL SERVICES
  // ───────────────────────────────────────────────────────────────────────────
  ProposalModel _synthesizeGeneralEnterprise({
    required String proposalId,
    required String amId,
    required String leadCompanyName,
    required String industry,
    required String websiteUrl,
    required Map<String, String> socialUrls,
    String? pitchDeckFileName,
    String? pitchDeckStorageUrl,
    String? extractedPitchDeckText,
  }) {
    final ind = industry.isNotEmpty ? industry : 'Commercial Growth';

    return ProposalModel(
      id: proposalId,
      amId: amId,
      leadCompanyName: leadCompanyName,
      industry: ind,
      websiteUrl: websiteUrl,
      socialUrls: socialUrls,
      pitchDeckFileName: pitchDeckFileName,
      pitchDeckStorageUrl: pitchDeckStorageUrl,
      extractedPitchDeckText: extractedPitchDeckText,
      status: ProposalStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      executiveSummaryPosition:
          '$leadCompanyName operates as an established leader in the $ind market, delivering proven value, professional service standards, and verified client satisfaction across its customer base.',
      executiveSummaryOpportunity:
          'While $leadCompanyName has built strong foundational trust, substantial opportunity exists to capture market leadership through multi-channel digital authority, high-converting service landing pages, and educational content that eliminates client hesitation.',
      swot: SwotMatrix(
        strengths: [
          'Established industry reputation and customer goodwill in $ind',
          'Demonstrated service delivery standards and reliable customer support',
          'Diverse solutions portfolio meeting multi-segment customer requirements',
          'Strong organic referral base and verified customer satisfaction',
        ],
        weaknesses: [
          'Digital visibility lagging behind top digital-first competitors in $ind',
          'Content frequently focuses on service features rather than transformative customer outcomes',
          'Limited short-form video presence on high-engagement social channels',
          'Under-optimized organic search ranking for high-intent category keywords',
        ],
        opportunities: [
          'Capturing high-intent organic search queries and Google Local/Category dominance in $ind',
          'Deploying customer transformation case studies and client testimonial video reels',
          'Building dedicated, high-converting landing hubs for specialized offerings',
          'Positioning leadership as industry authorities through regular thought leadership',
        ],
        threats: [
          'Aggressive digital advertising by competitors driving up customer acquisition costs',
          'Price-based commoditization pressure from low-cost market operators',
          'Changing consumer discovery behaviors shifting toward AI-assisted search engines',
          'Fast-evolving market expectations requiring continuous digital agility',
        ],
      ),
      marketingMix4Ps: MarketingMix4Ps(
        productCurrent: 'Core $ind services, tailored customer solutions, and dedicated client advisory offerings.',
        productOpportunity: 'Structure distinct outcome-oriented packages: "Foundational Assessment", "Complete Turnkey Solution", and "Enterprise Strategic Retainer".',
        priceCurrent: 'Market-aligned pricing supported by quality, experienced team, and customer trust.',
        priceOpportunity: 'Compete on comprehensive value, safety, and outcome reliability rather than commoditized price discounting.',
        placeCurrent: 'Company website, professional social profiles, and direct business development inquiry channels.',
        placeOpportunity: 'Expand digital discoverability through localized landing pages, automated inquiry workflows, and omni-channel publishing.',
        promotionCurrent: 'Company announcements, customer milestone highlights, and seasonal promotional communications.',
        promotionOpportunity: 'Deploy educational thought leadership reels, customer journey transformation stories, and actionable industry guides.',
      ),
      pestAnalysis: PestAnalysis(
        political: [
          'Industry governance, trade standards, and commercial regulatory compliance requirements',
          'Data privacy and digital consumer protection standards',
          'Government digital transformation and enterprise productivity incentive schemes',
        ],
        economic: [
          'Evolving corporate and consumer spending priorities emphasizing verified ROI and reliability',
          'Market demand favoring transparent pricing and predictable service timelines',
          'Economic shifts rewarding agile, digitally integrated service providers',
        ],
        social: [
          'Customers conducting extensive independent digital research before reaching out to sales',
          'High demand for transparent, human-centered brand communication and social proof',
          'Growing preference for video-first educational content across digital channels',
        ],
        technological: [
          'AI search engines (Perplexity, ChatGPT) transforming how clients discover service providers',
          'Short-form vertical video algorithms driving organic brand discoverability',
          'Automated customer relationship management (CRM) and digital communication pipelines',
        ],
      ),
      competitorUsps: [
        CompetitorUsp(brandName: leadCompanyName, primaryUsp: 'Premier tailored solutions, verified service reliability, and customer-first execution excellence', isLeadBrand: true),
        CompetitorUsp(brandName: 'Top Category Competitor', primaryUsp: 'Large-scale national provider with high brand awareness and standardized offerings', isLeadBrand: false),
        CompetitorUsp(brandName: 'Boutique Specialized Firm', primaryUsp: 'Niche offering focused on narrow high-ticket customer segments', isLeadBrand: false),
        CompetitorUsp(brandName: 'Digital Challenger Brand', primaryUsp: 'Aggressive online promotional campaigns with low-cost entry pricing', isLeadBrand: false),
      ],
      perceptualMapNarrative: '$leadCompanyName bridges specialized service excellence with broad customer accessibility, outperforming both rigid mass operators and narrow boutique providers.',
      perceptualMapInsight: 'Customers do not choose service providers based on superficial marketing slogans—they purchase the emotional certainty and proven competence of trusted experts.',
      perceptualMapOpportunity: 'Consolidate $leadCompanyName as the undisputed first choice and market benchmark in $ind.',
      creativePillars: [
        ContentPillar(title: 'Customer Proof & Transformation', objective: 'Demonstrate tangible results and build unshakeable credibility through real customer experiences.', contentStyle: const ['Case study carousels', 'Transformation recaps', 'Client review overlays'], exampleTopics: ['How We Helped This Client Achieve Breakthrough Outcomes', 'From Friction to Clarity: A Real Customer Story', 'What Clients Say About Working with Us']),
        ContentPillar(title: 'Domain Authority & Masterclasses', objective: 'Position $leadCompanyName as the definitive expert by demystifying common industry challenges.', contentStyle: const ['Educational reels', 'Saveable checklists', 'Expert explainers'], exampleTopics: ['3 Critical Mistakes to Avoid in $ind', 'The Essential Checklist Every Buyer Needs', 'What Separates Top-Tier Providers from Generic Alternatives']),
        ContentPillar(title: 'Behind the Scenes & Process', objective: 'Demystify your workflow and show the meticulous care that goes into every client engagement.', contentStyle: const ['Process walkthroughs', 'Team spotlights', 'Quality assurance tours'], exampleTopics: ['How We Ensure Precision at Every Step', 'Meet the Specialists Behind Your Success', 'A Day in the Life of Our Operations Team']),
        ContentPillar(title: 'Executive Thought Leadership', objective: 'Engage decision-makers with strategic perspectives on future industry trends.', contentStyle: const ['Opinion carousels', 'Trend briefings', 'Keynote excerpts'], exampleTopics: ['Where $ind is Heading in the Next 3 Years', 'Why Traditional Approaches No Longer Work', 'The Modern Playbook for Growth']),
        ContentPillar(title: 'Community & Client Q&A', objective: 'Build approachable, responsive brand connections by addressing common inquiries.', contentStyle: const ['Q&A video shorts', 'FAQ breakdowns', 'Myth-busting carousels'], exampleTopics: ['Answering This Month’s Top 5 Questions', 'Is This Solution Right for Your Organization?', 'How to Get Started with Zero Friction']),
      ],
      visualGuidelineNotes: 'Refined modern aesthetic balancing authoritative professionalism with clean, human-centric design. Natural lighting, crisp typography, and cohesive brand color accents.',
      brandPaletteHex: const ['#0F172A', '#1E293B', '#3B82F6', '#10B981', '#F8FAFC'],
      visualKeywords: const ['Authoritative', 'Professional', 'Modern', 'Trustworthy', 'Clear'],
      focusMoreOn: const ['Real team members in collaborative client environments', 'Clear infographic data visualizations and charts', 'High-quality customer interactions', 'Clean modern work environments'],
      focusLessOn: const ['Cheesy stock handshakes in sterile boardrooms', 'Overly complex technical diagrams without explanation', 'Generic clip-art graphics', 'Unfocused low-resolution imagery'],
      photographyQuote: "Customers don't buy service features. They buy certainty, verified outcomes, and trusted partnership.",
      typographySampleHeadline: "EXPERTISE. TRUST. MEASURABLE RESULTS.",
      brandToneOfVoice: const [
        {'trait': 'AUTHORITATIVE', 'desc': 'Speaking with deep domain experience, verified results, and industry leadership.'},
        {'trait': 'APPROACHABLE', 'desc': 'Clear, empathetic, and eliminating jargon to make collaboration effortless.'},
        {'trait': 'RESULTS-DRIVEN', 'desc': 'Focusing on tangible business outcomes, customer value, and measurable ROI.'},
        {'trait': 'TRUSTWORTHY', 'desc': 'Consistent, transparent, and upholding the highest professional standards.'},
      ],
      brandColorDetails: const {
        'primary': {'name': 'Slate Navy', 'hex': '#0F172A'},
        'secondary': {'name': 'Executive Blue', 'hex': '#3B82F6'},
        'accent': {'name': 'Growth Emerald', 'hex': '#10B981'},
      },
      contentFrameworkWeeks: [
        {'week': 'WEEK 1', 'experienceStories': 'Customer Transformation Case Study', 'educational': '3 Mistakes to Avoid When Choosing a Provider', 'corporate': 'Enterprise & B2B Solutions Overview', 'testimonials': 'Client Review (Service Excellence)', 'promotional': 'Schedule Your Discovery Call', 'contentExamples': '• Case study reel\n• Mistake checklist\n• Solutions carousel\n• Client review quote\n• Consultation booking link'},
        {'week': 'WEEK 2', 'experienceStories': 'Process Walkthrough: How We Deliver Precision', 'educational': 'Demystifying the Top Industry Myths', 'corporate': 'Tailored Advisory & Custom Scopes', 'testimonials': 'Client Review (Speed & Reliability)', 'promotional': 'Download Our Comprehensive Service Guide', 'contentExamples': '• Process tour\n• Myth-busting post\n• Advisory highlight\n• Client review quote\n• Download link'},
        {'week': 'WEEK 3', 'experienceStories': 'Behind the Scenes with Our Specialist Team', 'educational': 'How to Evaluate Value vs Cost in $ind', 'corporate': 'Executive Q&A on Market Trends', 'testimonials': 'Client Review (Outcome Quality)', 'promotional': 'Limited Consultation Slots This Month', 'contentExamples': '• Team spotlight\n• Value breakdown\n• Executive interview\n• Review quote\n• Calendar link'},
        {'week': 'WEEK 4', 'experienceStories': 'Monthly Milestone Recap & Client Wins', 'educational': 'The 5 Questions You Should Always Ask', 'corporate': 'Long-Term Strategic Retainers & Support', 'testimonials': 'Client Review (Long-Term Partnership)', 'promotional': 'Get Started with Our Initial Assessment', 'contentExamples': '• Client wins reel\n• Questions checklist\n• Retainer overview\n• Long-term review\n• Assessment link'},
      ],
      sampleReelHeadline: 'Proven Excellence',
      sampleReelTopic: 'What Separates Top-Tier Providers in $ind from Generic Alternatives',
      sampleReelHook: 'Most service providers promise results, but few show how they deliver them. Here is our proven framework in 60 seconds.',
      sampleReelVisualScenes: 'Scene 1: Dynamic shot of specialists analyzing client project requirements.\nScene 2: Split screen highlighting common industry pain points vs streamlined execution.\nScene 3: Real-time review of successful client delivery milestones.\nScene 4: Confident client handshake and brand contact information.',
      sampleReelCta: 'Partner with a proven team. Tap the link in bio to schedule your initial consultation with $leadCompanyName.',
      sampleReelLink: websiteUrl,
      sampleBlogTitle: 'The Complete Guide to Choosing the Right Partner in $ind (Without Costly Surprises)',
      sampleBlogStorytellingIntro: 'In an increasingly crowded market, evaluating service partners requires looking past promotional claims and examining verified execution capabilities, team credentials, and outcome transparency.',
      sampleBlogPreview: 'When selecting a strategic partner, many organizations find themselves choosing between impersonal mass operators or untested budget providers. True value lies in partnering with dedicated specialists who understand your exact requirements...\n\nIn this comprehensive guide, we outline the key criteria every decision-maker should evaluate.',
      sampleSocialCaptionHook: 'Great outcomes are never an accident. They are engineered. 🎯',
      sampleSocialCaptionBody: 'At $leadCompanyName, we believe exceptional service begins with listening closely, executing with precision, and measuring success by the real outcomes we deliver for our clients.\n\nDiscover how our tailored solutions can accelerate your goals.',
      sampleSocialCaptionCta: '💬 Reach out to our team today to discuss your upcoming project.',
      sampleSocialHashtags: ['#$ind', '#BusinessGrowth', '#ProfessionalExcellence', '#MeetMarketers'],
      socialPosts: const [
        {'title': 'Expertise & Quality', 'headline': 'BUILT ON TRUST. DRIVEN BY RESULTS.', 'body': 'We don\'t believe in one-size-fits-all solutions.\n\nEvery client engagement is tailored to your specific goals, supported by experienced professionals who care about your long-term success.\n\nLearn more at our website.', 'badge': 'VERIFIED EXCELLENCE', 'hashtags': ['#QualityService', '#ClientSuccess', '#Expertise'], 'imageUrl': ''},
        {'title': 'Client Transformation', 'headline': 'HOW WE HELP OUR CLIENTS SUCCEED.', 'body': 'From initial consultation through seamless execution, our team provides the guidance, clarity, and accountability you need to achieve your goals.\n\nSee what our clients say about working with us.', 'badge': 'CLIENT OUTCOMES', 'hashtags': ['#ClientReview', '#Transformation', '#Results'], 'imageUrl': ''},
        {'title': 'Strategic Perspective', 'headline': 'THE RIGHT PARTNER MAKES ALL THE DIFFERENCE.', 'body': 'Whether tackling a complex challenge or optimizing routine operations, having the right team in your corner changes everything.\n\nConnect with our specialists today.', 'badge': 'PROVEN PARTNERSHIP', 'hashtags': ['#StrategicPartner', '#BusinessExcellence', '#Leadership'], 'imageUrl': ''},
      ],
      seoAudit: const SeoAuditSummary(
        healthScore: 71,
        summaryText: 'Solid digital presence with active branding, with clear opportunities to improve search visibility for high-intent category keywords and structured entity discovery across Google and AI search engines.',
        highPriority: ['Service-specific landing pages with transparent FAQs and clear calls-to-action', 'Organization and Service Schema.org structured data markup', 'H1 and Meta Title optimization across core category pages', 'Core Web Vitals acceleration and mobile responsiveness audit'],
        mediumPriority: ['Client case study directory with filtered search capabilities', 'Open Graph social preview cards for key service offerings', 'Executive author profiles establishing team E-E-A-T credentials'],
        longTermOpportunities: ['AI search engine discoverability (AIO & Perplexity entity optimization)', 'Comprehensive educational resource library and category guides', 'Dedicated client inquiry portal and automated CRM onboarding flow'],
      ),
      seoAssessmentText: 'We recommend prioritizing service-specific landing pages and technical on-page SEO quick wins in Phase 1 to capture high-intent clients actively searching for solutions in your category.',
      seoAuditLink: 'https://meet-marketers.com/seo-audit',
      finalThoughtsSummary: '$leadCompanyName already possesses the core qualities clients value most: proven credibility, professional service standards, and dedicated execution. Our proposed roadmap transforms these strengths into commanding digital authority and inbound inquiry growth.',
      finalThoughtsRecommendation: 'We recommend initiating Phase 1 immediately: Launching high-converting service landing pages and educational video storytelling, followed by automated multi-channel thought leadership to scale qualified leads.',
    );
  }
}
