import '../../core/app_copy.dart';
import '../../shared/legal_constants.dart';

class LegalSection {
  const LegalSection({required this.title, required this.points});

  final String title;
  final List<String> points;
}

String nightRadarDisclaimerSummary(AppCopy copy) {
  return copy.text(
    it: 'NightRadar aiuta a gestire eventi, liste e tavoli, ma l ingresso finale resta deciso da locale, sicurezza e PR.',
    en: 'NightRadar helps manage events, guest lists, and tables, but final admission is still decided by venues, security, and promoters.',
  );
}

String nightRadarPrivacySummary(AppCopy copy) {
  return copy.text(
    it: 'NightRadar usa solo i dati necessari per account, prenotazioni, richieste ai PR, accessi ed export operativi.',
    en: 'NightRadar uses only the data needed for accounts, reservations, promoter requests, entry flows, and operational exports.',
  );
}

List<LegalSection> nightRadarDisclaimerSections(AppCopy copy) {
  return [
    LegalSection(
      title: copy.text(it: 'Uso del servizio', en: 'Service usage'),
      points: [
        copy.text(
          it: 'Usi NightRadar in modo responsabile e confermi di rispettare limiti di eta, documenti richiesti e regole applicabili.',
          en: 'You use NightRadar responsibly and confirm that you meet age limits, document requirements, and applicable rules.',
        ),
        copy.text(
          it: 'Orari, prezzi, lineup, disponibilita, tavoli e limiti di eta possono cambiare in qualsiasi momento per decisione di PR, organizzatori o locale.',
          en: 'Timings, prices, lineup, availability, tables, and age limits may change at any time at the discretion of promoters, organizers, or the venue.',
        ),
        copy.text(
          it: 'Radar, suggerimenti e tempi auto sono indicativi e non sostituiscono traffico live, navigazione reale o conferma finale dell ingresso.',
          en: 'Radar, suggestions, and drive times are indicative and do not replace live traffic, real navigation, or final confirmation of entry.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Accesso agli eventi', en: 'Event access'),
      points: [
        copy.text(
          it: 'L ammissione finale resta sempre in capo al locale e al personale di sicurezza, anche con QR, codice o nominativo in lista.',
          en: 'Final admission always remains under the control of the venue and security staff, even with a QR, code, or guest-list entry.',
        ),
        copy.text(
          it: 'Capienza, comportamento, dress code, documenti mancanti o policy interne possono portare a un rifiuto di accesso indipendente da NightRadar.',
          en: 'Capacity limits, behavior, dress code, missing documents, or internal policies may lead to denied entry independently from NightRadar.',
        ),
        copy.text(
          it: 'WhatsApp, Telegram, email o inbox NightRadar facilitano il contatto, ma non garantiscono risposta, conferma o ingresso.',
          en: 'WhatsApp, Telegram, email, or the NightRadar inbox facilitate contact, but they do not guarantee a reply, confirmation, or entry.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Ruolo di NightRadar', en: 'NightRadar role'),
      points: [
        copy.text(
          it: 'NightRadar e uno strumento digitale tra utenti e PR; i locali ricevono i dati finali e applicano regole proprie.',
          en: 'NightRadar is a digital tool between users and promoters; venues receive final data and apply their own rules.',
        ),
        copy.text(
          it: 'Schede PR, rating, like, badge o highlight sono segnali interni e non certificazioni o garanzie di risultato.',
          en: 'Promoter cards, ratings, likes, badges, or highlights are internal signals and not certifications or guaranteed results.',
        ),
        copy.text(
          it: 'Se liste o riepiloghi escono dalla piattaforma, per esempio via PDF, copia e incolla o chat, NightRadar non controlla piu la gestione successiva dei terzi.',
          en: 'If lists or summaries leave the platform, for example via PDF, copy and paste, or chat, NightRadar no longer controls how third parties handle them afterwards.',
        ),
      ],
    ),
  ];
}

List<LegalSection> nightRadarPrivacySections(AppCopy copy) {
  return [
    LegalSection(
      title: copy.text(it: 'Titolare e ambito', en: 'Controller and scope'),
      points: [
        copy.text(
          it: 'NightRadar e il riferimento operativo per i trattamenti necessari a account, liste, richieste ai PR, accessi e funzioni collegate al servizio.',
          en: 'NightRadar is the operational point of reference for the processing needed for accounts, guest lists, promoter requests, entry flows, and related service functions.',
        ),
        _privacyContactLine(copy),
        copy.text(
          it: 'Questa informativa copre sito pubblico, area utenti, area PR e funzioni web/app collegate allo stesso backend.',
          en: 'This notice covers the public site, the user area, the promoter area, and connected web/app functions using the same backend.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Dati raccolti', en: 'Collected data'),
      points: [
        copy.text(
          it: 'Raccogliamo dati account come nome, email e profilo inseriti da utente o PR, inclusi bio, avatar e social pubblici se scelti dal PR.',
          en: 'We collect account data such as name, email, and profile details entered by the user or promoter, including bio, avatar, and public social handles if chosen by the promoter.',
        ),
        copy.text(
          it: 'Quando prenoti o gestisci una lista trattiamo dati operativi come nome, cognome, telefono, email, nome lista o tavolo, numero partecipanti, note ed eventuali credenziali di accesso.',
          en: 'When you reserve or manage a list, we process operational data such as name, surname, phone, email, list or table name, party size, notes, and any entry credentials.',
        ),
        copy.text(
          it: 'Registriamo anche i dati tecnici minimi utili a funzionamento, sicurezza, prevenzione abusi, consensi legali e preferenze salvate localmente.',
          en: 'We also record the minimum technical data needed for operation, security, abuse prevention, legal consents, and locally stored preferences.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(
        it: 'Finalita e basi del trattamento',
        en: 'Purposes and legal bases',
      ),
      points: [
        copy.text(
          it: 'Usiamo i dati per autenticazione, guest list, wallet, richieste ai PR, supporto operativo e consegna dei dati finali ai soggetti coinvolti nell evento.',
          en: 'We use data for authentication, guest lists, wallet flows, promoter requests, operational support, and delivery of final data to the parties involved in the event.',
        ),
        copy.text(
          it: 'Le basi del trattamento sono esecuzione del servizio richiesto, misure precontrattuali, obblighi di legge ove applicabili e interesse legittimo a sicurezza e prevenzione abusi; il consenso e usato dove richiesto.',
          en: 'The legal bases are performance of the requested service, pre-contractual steps, legal obligations where applicable, and legitimate interest in security and abuse prevention; consent is used where required.',
        ),
        copy.text(
          it: 'I dati possono essere usati anche per audit operativo, contestazioni, prevenzione frodi e miglioramento del prodotto in modo proporzionato.',
          en: 'Data may also be used for operational audits, disputes, fraud prevention, and proportionate product improvement.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(
        it: 'Condivisione, canali esterni e tempi',
        en: 'Sharing, external channels, and retention',
      ),
      points: [
        copy.text(
          it: 'I dati strettamente necessari all evento possono essere condivisi con PR, locale, organizzatori o collaboratori coinvolti nella gestione di liste e accessi.',
          en: 'Data strictly required for the event may be shared with promoters, venues, organizers, or collaborators involved in list and entry management.',
        ),
        copy.text(
          it: 'Se utenti o PR usano WhatsApp, Telegram, email, PDF o copia e incolla, quei canali operano secondo le proprie policy, fuori dal controllo diretto di NightRadar.',
          en: 'If users or promoters use WhatsApp, Telegram, email, PDF, or copy and paste, those channels operate under their own policies, outside NightRadar direct control.',
        ),
        copy.text(
          it: 'Conserviamo i dati per il tempo necessario a finalita operative, sicurezza e contestazioni. In via standard, i dati legati a eventi chiusi vengono rimossi dopo 6 mesi, salvo obblighi di legge o esigenze motivate.',
          en: 'We retain data for the time needed for operational purposes, security, and disputes. As a standard rule, data linked to closed events is removed after 6 months, unless legal obligations or justified needs require longer retention.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Diritti e contatti', en: 'Rights and contacts'),
      points: [
        copy.text(
          it: 'Puoi chiedere accesso, aggiornamento, rettifica o cancellazione dei dati tramite i canali ufficiali NightRadar, salvo obblighi di conservazione di legge.',
          en: 'You may request access, update, rectification, or deletion of your data through official NightRadar channels, subject to legal retention obligations.',
        ),
        copy.text(
          it: 'Per richieste privacy, diritti o chiarimenti puoi contattare $nightRadarPrivacyContactLabel a $nightRadarPrivacyContactEmail. Restano fermi gli altri diritti previsti dalla normativa applicabile.',
          en: 'For privacy requests, rights, or clarifications you may contact $nightRadarPrivacyContactLabel at $nightRadarPrivacyContactEmail. The other rights provided by the applicable law remain unaffected.',
        ),
      ],
    ),
  ];
}

String legalVersionLabel(AppCopy copy) {
  return copy.text(
    it: '$nightRadarLegalVersion  Aggiornato il $nightRadarLegalEffectiveDate',
    en: '$nightRadarLegalVersion  Updated on $nightRadarLegalEffectiveDate',
  );
}

String _privacyContactLine(AppCopy copy) {
  return copy.text(
    it: 'Per richieste privacy e diritti puoi scrivere a $nightRadarPrivacyContactEmail.',
    en: 'For privacy requests and data-subject rights you can write to $nightRadarPrivacyContactEmail.',
  );
}
