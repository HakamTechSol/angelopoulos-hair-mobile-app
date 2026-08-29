import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loyalty_app/Services/language_service.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Terms & Conditions content in multiple languages
  Map<String, Map<String, String>> getTermsContent() {
    return {
      'en': {
        'title': 'Terms & Conditions',
        'subtitle': 'Please read our terms and conditions carefully',
        'personalData': 'Personal Data',
        'personalDataContent':
            '''The processing of personal data is carried out in accordance with the provisions of the General Data Protection Regulation (GDPR 2016/679), any specific national and European legislation for certain sectors, the applicable Greek legislation for the protection of personal data, as well as for the protection of personal data and privacy in the field of electronic communications and the decisions of the Personal Data Protection Authority.

During your visit to the angelopouloshair pages and in order to order products, as well as to ensure the possibility of communication with you so that we can inform you about our new products, you may be asked to declare information about you (name, telephone, city, email address, etc.). Any personal data you declare anywhere on the pages and services of the website www.angelopouloshair.gr, are intended exclusively for ensuring the operation of the corresponding service and may not be used by any third party.''',
        'cookies': 'Cookies',
        'cookiesContent':
            '''To be able to offer personalized service, most large companies use alphanumeric identification files, called cookies. Cookies are small files (text files), which are sent and stored on the user's computer, allowing websites like www.angelopouloshair.gr to function smoothly and without technical anomalies, to collect multiple user choices, to recognize frequent users, to facilitate their access to it, and to collect data to improve the content of the website.

We use cookies to provide you with information and to process your orders while every time you exit the site they are automatically deleted.''',
        'generalTerms': 'General Terms',
        'generalTermsContent':
            '''The Angelopouloshair Loyalty App reserves the right to unilaterally modify or renew the present terms and conditions of transactions made through its electronic store, according to its needs and trading practices. The Angelopouloshair Loyalty App undertakes the obligation to inform users about any modifications as well as any change, through the website of this electronic store.''',
        'providedInfo': 'Provided Information & Products',
        'providedInfoContent':
            '''The Angelopouloshair Loyalty App is committed to the completeness and validity of the information presented on the website www.angelopouloshair.gr and in the app, both regarding the existence of the essential characteristics that are described for each product it offers, as well as for the accuracy of the data concerning the services provided by the electronic store www.angelopouloshair.gr.''',
        'liability': 'Limitation of Liability',
        'liabilityContent':
            '''The Angelopouloshair Loyalty App cannot provide any guarantee for the availability of products, but guarantees timely information to end consumers about their unavailability. The electronic store www.angelopouloshair.gr is not responsible for any technical problems that may occur to users when they attempt to access the website.''',
        'copyright': 'Intellectual Property Rights',
        'copyrightContent':
            '''All content of the web pages posted on the Angelopouloshair Loyalty App, including images, graphics, photographs, designs, texts, services and products provided constitute intellectual property of www.angelopouloshair.gr and are protected under the relevant provisions of Greek law, European law and international conventions.''',
        'userObligations': 'User Obligations',
        'userObligationsContent':
            '''Users of the www.angelopouloshair.gr websites and the Angelopouloshair Loyalty App accept that they will not use them to send, publish, email or transmit in other ways any content that is illegal, harmful, threatening, offensive, annoying, defamatory, defamatory, vulgar, indecent, libelous.''',
        'disputeResolution': 'Electronic Dispute Resolution',
        'disputeResolutionContent':
            '''According to Directive 2013/11/EC, which was incorporated in Greece with the Joint Ministerial Decision 70330/2015, the possibility of electronic resolution of consumer disputes is now provided through the Alternative Dispute Resolution (ADR) procedure throughout the European Union.''',
        'codeOfEthics': 'Code of Ethics',
        'codeOfEthicsContent':
            '''The operation of the store is governed by the use of the applicable Code of Ethics.''',
        'companyDetails': 'Company Details',
        'companyDetailsContent': '''ANGELOPOULOS HAIR & BEAUTY IKE
Char. Trikoupi 186 & Tatoiou 75, Kifisia
VAT: 800895616, Tax Office: Kifisias
GEMI No: 144349601000''',
        'accept': 'I Accept',
        'decline': 'Decline',
      },

      'el': {
        'title': 'Όροι & Προϋποθέσεις',
        'subtitle':
            'Παρακαλούμε διαβάστε προσεκτικά τους όρους και προϋποθέσεις μας',
        'personalData': 'Προσωπικά Δεδομένα',
        'personalDataContent':
            '''Η επεξεργασία των προσωπικών δεδομένων γίνεται σύμφωνα με τις διατάξεις του Γενικού Κανονισμού Προστασίας Προσωπικών Δεδομένων (ΓΚΠΔ 2016/679), τυχόν ειδικότερης εθνικής και ευρωπαϊκής νομοθεσίας για ορισμένους τομείς, της εκάστοτε ισχύουσας ελληνικής νομοθεσίας για την προστασία δεδομένων προσωπικού χαρακτήρα.

Κατά την επίσκεψή σας στις σελίδες του angelopouloshair και προκειμένου να παραγγείλετε προϊόντα, αλλά και για να διασφαλισθεί η δυνατότητα επικοινωνίας μαζί σας ώστε να σας ενημερώνουμε για νέα προϊόντα μας, είναι πιθανό να σας ζητηθεί να δηλώσετε στοιχεία που σας αφορούν.''',
        'cookies': 'Cookies',
        'cookiesContent':
            '''Για να μπορούν να προσφέρουν προσωποποιημένη εξυπηρέτηση, οι περισσότερες μεγάλες εταιρείες χρησιμοποιούν αλφαριθμητικά αρχεία αναγνώρισης, τα λεγόμενα cookies. Τα cookies είναι μικρά αρχεία (text files), τα οποία αποστέλλονται και φυλάσσονται στον ηλεκτρονικό υπολογιστή του χρήστη.

Χρησιμοποιούμε τα cookies για να σας παρέχουμε πληροφορίες και να διεκπεραιώνονται οι παραγγελίες σας ενώ σε κάθε έξοδό σας από το site διαγράφονται αυτόματα.''',
        'generalTerms': 'Γενικοί Όροι',
        'generalTermsContent':
            '''Το Angelopouloshair Loyalty App διατηρεί το δικαίωμα να τροποποιεί μονομερώς ή να ανανεώνει τους παρόντες όρους και τις προϋποθέσεις των συναλλαγών, που γίνονται μέσω του ηλεκτρονικού της καταστήματος, σύμφωνα με τις ανάγκες της και τα συναλλακτικά ήθη.''',
        'providedInfo': 'Παρεχόμενες Πληροφορίες & Προϊόντα',
        'providedInfoContent':
            '''Το Angelopouloshair Loyalty App δεσμεύεται ως προς την πληρότητα και την εγκυρότητα των πληροφοριών που παρατίθενται στην ιστοσελίδα της www.angelopouloshair.gr και στο app, τόσο όσον αφορά την ύπαρξη των ουσιωδών χαρακτηριστικών που κατά περίπτωση περιγράφονται για κάθε προϊόν που διαθέτει.''',
        'liability': 'Περιορισμός Ευθύνης',
        'liabilityContent':
            '''Το Angelopouloshair Loyalty App ουδεμία εγγύηση μπορεί να παράσχει για τη διαθεσιμότητα των προϊόντων, αλλά εγγυάται την έγκαιρη ενημέρωση των τελικών καταναλωτών περί της μη διαθεσιμότητάς τους.''',
        'copyright': 'Δικαιώματα Πνευματικής Ιδιοκτησίας',
        'copyrightContent':
            '''Όλο το περιεχόμενο των ιστοσελίδων, που αναρτάται στο Angelopouloshair Loyalty App, συμπεριλαμβανομένων εικόνων, γραφικών, φωτογραφιών, σχεδίων, κειμένων, παρεχόμενων υπηρεσιών και προϊόντων αποτελούν πνευματική ιδιοκτησία του www.angelopouloshair.gr.''',
        'userObligations': 'Υποχρεώσεις Χρήστη',
        'userObligationsContent':
            '''Οι χρήστες των ιστοσελίδων www.angelopouloshair.gr και του Angelopouloshair Loyalty App αποδέχονται ότι δεν θα χρησιμοποιούν αυτές για αποστολή, δημοσίευση, αποστολή με e-mail ή μετάδοση με άλλους τρόπους οποιουδήποτε περιεχομένου είναι παράνομο.''',
        'disputeResolution': 'Ηλεκτρονική Επίλυση Διαφορών',
        'disputeResolutionContent':
            '''Σύμφωνα με την Οδηγία 2013/11/ΕΚ, η οποία ενσωματώθηκε στην Ελλάδα με την ΚΥΑ 70330/2015, προβλέπεται πλέον και η δυνατότητα ηλεκτρονικής επίλυσης καταναλωτικών διαφορών.''',
        'codeOfEthics': 'Κώδικας Δεοντολογίας',
        'codeOfEthicsContent':
            '''Η λειτουργία του καταστήματος διέπεται από την χρήση του ισχύοντος Κώδικα Δεοντολογίας.''',
        'companyDetails': 'Στοιχεία Εταιρείας',
        'companyDetailsContent': '''ANGELOPOULOS HAIR & BEAUTY IKE
Χαρ. Τρικούπη 186 & Τατοΐου 75, Κηφισιά
ΑΦΜ: 800895616, ΔΟΥ: Κηφισιάς
ΑΡ. Γ.Ε.Μ.Η: 144349601000''',
        'accept': 'Αποδέχομαι',
        'decline': 'Απόρριψη',
      },

      'ro': {
        'title': 'Termeni și Condiții',
        'subtitle':
            'Vă rugăm să citiți cu atenție termenii și condițiile noastre',
        'personalData': 'Date Personale',
        'personalDataContent':
            '''Prelucrarea datelor cu caracter personal se efectuează în conformitate cu prevederile Regulamentului General privind Protecția Datelor (GDPR 2016/679), orice legislație națională și europeană specifică pentru anumite sectoare, legislația grecească aplicabilă pentru protecția datelor cu caracter personal.

În timpul vizitei dumneavoastră pe paginile angelopouloshair și pentru a comanda produse, precum și pentru a asigura posibilitatea comunicării cu dumneavoastră pentru a vă informa despre produsele noastre noi, vi se poate cere să declarați informații despre dumneavoastră.''',
        'cookies': 'Cookie-uri',
        'cookiesContent':
            '''Pentru a putea oferi servicii personalizate, majoritatea companiilor mari folosesc fișiere de identificare alfanumerice, numite cookie-uri. Cookie-urile sunt fișiere mici (fișiere text), care sunt trimise și stocate pe computerul utilizatorului.

Folosim cookie-uri pentru a vă furniza informații și pentru a procesa comenzile dumneavoastră, în timp ce de fiecare dată când ieșiți de pe site acestea sunt șterse automat.''',
        'generalTerms': 'Termeni Generali',
        'generalTermsContent':
            '''Angelopouloshair Loyalty App își rezervă dreptul de a modifica unilateral sau de a reînnoi prezentii termeni și condiții ale tranzacțiilor efectuate prin magazinul său electronic, conform necesităților sale și practicilor comerciale.''',
        'providedInfo': 'Informații și Produse Furnizate',
        'providedInfoContent':
            '''Angelopouloshair Loyalty App se angajează în ceea ce privește completitudinea și validitatea informațiilor prezentate pe site-ul web www.angelopouloshair.gr și în aplicație, atât în privința existenței caracteristicilor esențiale care sunt descrise pentru fiecare produs pe care îl oferă.''',
        'liability': 'Limitarea Responsabilității',
        'liabilityContent':
            '''Angelopouloshair Loyalty App nu poate oferi nicio garanție pentru disponibilitatea produselor, dar garantează informarea în timp util a consumatorilor finali despre indisponibilitatea acestora.''',
        'copyright': 'Drepturi de Proprietate Intelectuală',
        'copyrightContent':
            '''Tot conținutul paginilor web postat pe Angelopouloshair Loyalty App, inclusiv imagini, grafice, fotografii, desene, texte, servicii și produse furnizate constituie proprietate intelectuală a www.angelopouloshair.gr.''',
        'userObligations': 'Obligațiile Utilizatorilor',
        'userObligationsContent':
            '''Utilizatorii site-urilor web www.angelopouloshair.gr și ai Angelopouloshair Loyalty App acceptă că nu le vor folosi pentru a trimite, publica, trimite prin e-mail sau transmite în alte moduri orice conținut care este ilegal.''',
        'disputeResolution': 'Rezolvarea Electronică a Disputelor',
        'disputeResolutionContent':
            '''Conform Directivei 2013/11/CE, care a fost încorporată în Grecia prin Decizia Ministerială Comună 70330/2015, se prevede acum posibilitatea rezolvării electronice a disputelor de consum.''',
        'codeOfEthics': 'Codul de Etică',
        'codeOfEthicsContent':
            '''Funcționarea magazinului este guvernată de utilizarea Codului de Etică aplicabil.''',
        'companyDetails': 'Detalii Companie',
        'companyDetailsContent': '''ANGELOPOULOS HAIR & BEAUTY IKE
Char. Trikoupi 186 & Tatoiou 75, Kifisia
TVA: 800895616, Oficiul Fiscal: Kifisias
Nr. GEMI: 144349601000''',
        'accept': 'Accept',
        'decline': 'Refuz',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        final currentLanguage = localizationService.currentLocale.languageCode;
        final terms =
            getTermsContent()[currentLanguage] ?? getTermsContent()['en']!;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with back button and title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  terms['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                                Text(
                                  terms['subtitle']!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Scrollable content
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSection(
                                        terms['personalData']!,
                                        terms['personalDataContent']!,
                                        Icons.security,
                                      ),
                                      _buildSection(
                                        terms['cookies']!,
                                        terms['cookiesContent']!,
                                        Icons.cookie,
                                      ),
                                      _buildSection(
                                        terms['generalTerms']!,
                                        terms['generalTermsContent']!,
                                        Icons.description,
                                      ),
                                      _buildSection(
                                        terms['providedInfo']!,
                                        terms['providedInfoContent']!,
                                        Icons.info_outline,
                                      ),
                                      _buildSection(
                                        terms['liability']!,
                                        terms['liabilityContent']!,
                                        Icons.warning_amber,
                                      ),
                                      _buildSection(
                                        terms['copyright']!,
                                        terms['copyrightContent']!,
                                        Icons.copyright,
                                      ),
                                      _buildSection(
                                        terms['userObligations']!,
                                        terms['userObligationsContent']!,
                                        Icons.person_outline,
                                      ),
                                      _buildSection(
                                        terms['disputeResolution']!,
                                        terms['disputeResolutionContent']!,
                                        Icons.gavel,
                                      ),
                                      _buildSection(
                                        terms['codeOfEthics']!,
                                        terms['codeOfEthicsContent']!,
                                        Icons.verified_user,
                                      ),
                                      _buildSection(
                                        terms['companyDetails']!,
                                        terms['companyDetailsContent']!,
                                        Icons.business,
                                        isLast: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Action buttons
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(25),
                                    bottomRight: Radius.circular(25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.grey[700],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          terms['decline']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'NotoSans',
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFEC7103,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Text(
                                          terms['accept']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'NotoSans',
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEC7103).withOpacity(0.1),
                  const Color(0xFFEC7103).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEC7103).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC7103),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEC7103),
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Section content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[700],
                fontFamily: 'NotoSans',
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
