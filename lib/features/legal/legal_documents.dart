import '../../core/app_copy.dart';
import '../../shared/legal_constants.dart';

class LegalSection {
  const LegalSection({required this.title, required this.points});

  final String title;
  final List<String> points;
}

String nightRadarDisclaimerSummary(AppCopy copy) {
  return copy.text(
    it: 'NightRadar aiuta utenti e PR a gestire eventi, liste, tavoli, QR e contatti, ma resta uno strumento digitale: accesso finale, controlli e decisioni restano a persone e strutture coinvolte.',
    en: 'NightRadar helps users and promoters manage events, lists, tables, QR passes, and contacts, but it remains a digital tool: final access, checks, and decisions stay with the people and venues involved.',
  );
}

String nightRadarPrivacySummary(AppCopy copy) {
  return copy.text(
    it: 'NightRadar tratta i dati necessari a login, prenotazioni, QR, richieste ai PR, esportazione liste e alcune preferenze salvate localmente su browser o dispositivo.',
    en: 'NightRadar processes the data needed for login, reservations, QR passes, promoter requests, list exports, and some preferences stored locally on the browser or device.',
  );
}

List<LegalSection> nightRadarDisclaimerSections(AppCopy copy) {
  return [
    LegalSection(
      title: copy.text(it: 'Uso del servizio', en: 'Service usage'),
      points: [
        copy.text(
          it: 'Usi NightRadar sotto la tua responsabilita e confermi di avere l eta minima richiesta per l accesso agli eventi e per eventuali consumazioni secondo la normativa locale.',
          en: 'You use NightRadar under your own responsibility and confirm that you meet the minimum age required for event access and any consumption under local regulations.',
        ),
        copy.text(
          it: 'Informazioni come orari, lineup, prezzi, capienza, offerte, limiti di eta, tavoli o disponibilita possono cambiare in qualsiasi momento su decisione di PR, organizzatori o locale.',
          en: 'Information such as timings, lineup, prices, capacity, offers, age limits, tables, or availability may change at any time at the discretion of promoters, organizers, or the venue.',
        ),
        copy.text(
          it: 'NightRadar facilita contatti, guest list e condivisione dati operativi, ma non garantisce l ingresso, la priorita in coda o la disponibilita finale.',
          en: 'NightRadar facilitates contacts, guest lists, and operational data sharing, but it does not guarantee entry, queue priority, or final availability.',
        ),
        copy.text(
          it: 'I suggerimenti su stasera, domani o entro un certo tempo auto sono stime di discovery basate sui dati disponibili nell app e non sostituiscono navigazione reale, geolocalizzazione precisa o traffico live.',
          en: 'Suggestions for tonight, tomorrow, or within a certain drive time are discovery estimates based on the data available in the app and do not replace real navigation, precise geolocation, or live traffic.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Accesso agli eventi', en: 'Event access'),
      points: [
        copy.text(
          it: 'L ammissione finale resta sempre in capo al locale e al personale di sicurezza, anche in presenza di QR, prenotazione o nominativo in lista.',
          en: 'Final admission always remains under the control of the venue and security staff, even when a QR, reservation, or guest-list entry exists.',
        ),
        copy.text(
          it: 'Eventuali rifiuti di accesso dovuti a capienza, comportamento, dress code, documenti mancanti o policy interne non dipendono da NightRadar.',
          en: 'Any denial of entry due to capacity, behavior, dress code, missing documents, or internal policies is outside NightRadar responsibility.',
        ),
        copy.text(
          it: 'Ogni utente o PR si impegna a condividere dati corretti e a non usare la piattaforma per contenuti illeciti, impersonificazioni o pratiche ingannevoli.',
          en: 'Each user or promoter agrees to share accurate data and not use the platform for unlawful content, impersonation, or deceptive practices.',
        ),
        copy.text(
          it: 'Se il PR permette richieste via WhatsApp, Telegram, email o inbox NightRadar, il canale scelto serve a facilitare il contatto ma la risposta finale del PR non e garantita.',
          en: 'If the promoter allows requests via WhatsApp, Telegram, email, or the NightRadar inbox, the selected channel is meant to facilitate contact but a final promoter reply is not guaranteed.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Ruolo di NightRadar', en: 'NightRadar role'),
      points: [
        copy.text(
          it: 'NightRadar opera come strumento digitale di organizzazione e comunicazione fra utenti e PR; i locali ricevono dati finiti e possono applicare regole proprie.',
          en: 'NightRadar operates as a digital organization and communication tool between users and promoters; venues receive final data and may apply their own rules.',
        ),
        copy.text(
          it: 'NightRadar non fornisce consulenza legale, fiscale o di pubblica sicurezza e puo aggiornare queste condizioni operative quando il prodotto evolve.',
          en: 'NightRadar does not provide legal, tax, or public-safety advice and may update these operating terms as the product evolves.',
        ),
        copy.text(
          it: 'Schede PR, like, cuori, pollici su, rating, badge o highlight servono come segnali sociali e operativi della piattaforma e non costituiscono certificazione, endorsement o garanzia di risultato.',
          en: 'Promoter cards, likes, hearts, thumbs up, ratings, badges, or highlights act as social and operational signals of the platform and do not amount to certification, endorsement, or guaranteed results.',
        ),
        copy.text(
          it: 'Quando liste o riepiloghi vengono esportati o inviati fuori dalla piattaforma, per esempio via copia e incolla, PDF, WhatsApp, Telegram o email, NightRadar non controlla piu la gestione successiva di quei contenuti da parte di terzi.',
          en: 'When lists or summaries are exported or sent outside the platform, for example via copy and paste, PDF, WhatsApp, Telegram, or email, NightRadar no longer controls how third parties handle those contents afterwards.',
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
          it: 'NightRadar team agisce come riferimento operativo per i trattamenti necessari a account, guest list, richieste ai PR, QR e funzioni collegate al servizio.',
          en: 'The NightRadar team acts as the operational point of reference for the processing needed for accounts, guest lists, promoter requests, QR passes, and service-related functions.',
        ),
        _privacyContactLine(copy),
        copy.text(
          it: 'Questa informativa copre il sito pubblico, l area utenti, l area PR e le funzioni mobile web o app che usano lo stesso backend NightRadar.',
          en: 'This notice covers the public site, the user area, the promoter area, and the mobile web or app functions that use the same NightRadar backend.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Dati raccolti', en: 'Collected data'),
      points: [
        copy.text(
          it: 'Raccogliamo dati account come nome, email e dati profilo inseriti dall utente o dal PR, inclusi bio, avatar e social pubblici se il PR sceglie di mostrarli.',
          en: 'We collect account data such as name, email, and profile data entered by the user or promoter, including bio, avatar, and public social handles if the promoter chooses to show them.',
        ),
        copy.text(
          it: 'Quando prenoti, invii richieste o gestisci una lista, possiamo trattare dati operativi come nome ospite, cognome, telefono, email, nome lista o tavolo, numero partecipanti, note, evento scelto e token QR.',
          en: 'When you reserve, send requests, or manage a list, we may process operational data such as guest name, surname, phone, email, list or table name, party size, notes, selected event, and QR token.',
        ),
        copy.text(
          it: 'Possiamo registrare dati tecnici minimi necessari al funzionamento del servizio, alla sicurezza e alla prevenzione di abusi, oltre a dati di consenso legale e versione dei testi accettati.',
          en: 'We may record the minimum technical data required for the service to operate, for security, and for abuse prevention, as well as legal-consent data and the version of the accepted texts.',
        ),
        copy.text(
          it: 'Alcune preferenze vengono salvate localmente sul browser o dispositivo, per esempio lingua, accettazione legale, citta di partenza, tempo auto massimo, PR fidati, viewer token dei like anonimi e storico locale dei like evento.',
          en: 'Some preferences are stored locally on the browser or device, for example language, legal acceptance, starting city, maximum drive time, trusted promoters, the anonymous-like viewer token, and the local history of event likes.',
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
          it: 'Usiamo i dati per autenticazione, gestione wallet, creazione guest list, richieste ai PR, condivisione con soggetti coinvolti nell evento, consegna dei dati finali al locale o all organizzatore e supporto operativo.',
          en: 'We use data for authentication, wallet management, guest-list creation, promoter requests, sharing with parties involved in the event, delivery of final data to the venue or organizer, and operational support.',
        ),
        copy.text(
          it: 'Le basi del trattamento dipendono dal flusso: esecuzione del servizio richiesto dall utente, misure precontrattuali su richiesta, obblighi di legge ove applicabili e interesse legittimo alla sicurezza, al corretto funzionamento e alla prevenzione di abusi; il consenso e usato quando richiesto in modo specifico, come per l accettazione iniziale dei testi legali.',
          en: 'The legal bases depend on the flow: performance of the service requested by the user, pre-contractual steps taken at the user request, legal obligations where applicable, and legitimate interest in security, proper operation, and abuse prevention; consent is used where specifically requested, such as for the initial acceptance of the legal texts.',
        ),
        copy.text(
          it: 'I dati possono essere usati anche per audit operativo, prevenzione frodi, gestione contestazioni e miglioramento del prodotto senza usare piu dati del necessario rispetto ai flussi principali.',
          en: 'Data may also be used for operational audits, fraud prevention, dispute handling, and product improvement without using more data than necessary compared with the main flows.',
        ),
        copy.text(
          it: 'I like anonimi agli eventi servono come segnale di interesse e usano un identificativo pseudonimo locale del browser o dispositivo; NightRadar non usa questa funzione come verifica di identita o geolocalizzazione precisa.',
          en: 'Anonymous event likes are used as an interest signal and rely on a pseudonymous local browser or device identifier; NightRadar does not use this feature as an identity check or precise geolocation tool.',
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
          it: 'I dati strettamente necessari all evento possono essere condivisi con PR, locale, organizzatori o collaboratori coinvolti nell organizzazione, nella gestione liste e nell accesso all evento.',
          en: 'Data strictly required for the event may be shared with promoters, venues, organizers, or collaborators involved in organization, list handling, and event access.',
        ),
        copy.text(
          it: 'Se utente o PR scelgono di contattarsi o condividere liste tramite WhatsApp, Telegram, email, PDF o copia e incolla, quei canali e i relativi destinatari operano secondo le proprie policy e la propria autonomia rispetto a NightRadar.',
          en: 'If users or promoters choose to contact each other or share lists through WhatsApp, Telegram, email, PDF, or copy and paste, those channels and their recipients operate under their own policies and independently from NightRadar.',
        ),
        copy.text(
          it: 'Conserviamo i dati per il tempo necessario alle finalita operative, agli obblighi di sicurezza e alla gestione di contestazioni o supporto. Per impostazione operativa standard, i dati legati a eventi chiusi vengono rimossi dopo 6 mesi, salvo esigenze di sicurezza, contestazioni aperte o obblighi di legge che richiedano una conservazione piu lunga.',
          en: 'We retain data for the time required for operational purposes, security obligations, and the handling of disputes or support. As a standard operational setting, data linked to closed events is removed after 6 months, unless security needs, open disputes, or legal obligations require longer retention.',
        ),
        copy.text(
          it: 'I dati salvati solo in locale sul dispositivo o browser restano fino a cancellazione da parte dell utente, reset dell app o pulizia dello storage locale.',
          en: 'Data stored only locally on the device or browser remains until deleted by the user, the app is reset, or local storage is cleared.',
        ),
      ],
    ),
    LegalSection(
      title: copy.text(it: 'Diritti e contatti', en: 'Rights and contacts'),
      points: [
        copy.text(
          it: 'Puoi chiedere accesso, aggiornamento, rettifica o cancellazione dei dati attraverso i canali ufficiali NightRadar, salvo obblighi di conservazione previsti dalla legge.',
          en: 'You may request access, update, rectification, or deletion of your data through official NightRadar channels, subject to legal retention obligations.',
        ),
        copy.text(
          it: 'Per richieste privacy, diritti o chiarimenti operativi puoi contattare $nightRadarPrivacyContactLabel a $nightRadarPrivacyContactEmail.',
          en: 'For privacy requests, rights, or operational clarifications you may contact $nightRadarPrivacyContactLabel at $nightRadarPrivacyContactEmail.',
        ),
        copy.text(
          it: 'Se ritieni che il trattamento non sia corretto, restano fermi gli altri diritti previsti dalla normativa applicabile e la possibilita di rivolgerti all autorita competente.',
          en: 'If you believe the processing is not correct, the other rights provided by the applicable law and the possibility of contacting the competent authority remain unaffected.',
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
