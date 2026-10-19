import '../models/story_model.dart';
import '../models/story_node_model.dart';
import '../models/story_choice_model.dart';
import '../models/story_ending_model.dart';
import '../models/comment_model.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';

class SampleData {
  SampleData._();

  static final UserModel defaultCurrentUser = UserModel(
    uid: 'user_alex_twist',
    email: 'alex.rivers@twist.app',
    displayName: 'Alex Rivers',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    bio: 'Interactive story voyager 🎬 Finding all the secret endings.',
    storiesPlayedCount: 14,
    endingsFoundCount: 29,
    choicesMadeCount: 78,
    followersCount: 1420,
    followingCount: 382,
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
  );

  // Stories
  static List<StoryModel> getStories() {
    return [
      StoryModel(
        id: 'story_one_last_message',
        titleMap: {
          'en': 'One Last Message',
          'ta': 'கடைசி செய்தி',
          'tanglish': 'Oru Kadaisi Message',
        },
        descriptionMap: {
          'en': 'One message changed everything. On a stormy night in the St. Jude dorms, an unknown caller whispers a warning that tears your reality apart.',
          'ta': 'ஒரு செய்தி எல்லாவற்றையும் மாற்றியது. செயின்ட் ஜூட்ஸ் விடுதியில் புயல் வீசும் இரவில், தெரியாத எண்ணிலிருந்து வரும் எச்சரிக்கை உங்கள் நிஜத்தையே மாற்றுகிறது.',
          'tanglish': 'Oru message ellathayum maathiduthu. St. Jude dorms-la oru mazhai night, yaaro theriyadha aalu sonna warning unga reality-aye mathi podudhu.',
        },
        availableLanguages: ['en', 'ta', 'tanglish'],
        coverUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80',
        category: 'Mystery',
        categories: ['Mystery', 'College', 'Thriller'],
        creatorId: 'creator_kavin',
        creatorName: 'Kavin Rao',
        creatorAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&auto=format&fit=crop&q=80',
        duration: '8 min',
        plays: 125400,
        likes: 34800,
        commentsCount: 642,
        endingsCount: 5,
        startNodeId: 'olm_node_1',
        isSaved: false,
        isLiked: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      StoryModel(
        id: 'story_crimson_manor',
        titleMap: {
          'en': 'The Crimson Manor',
          'ta': 'சிவப்பு மாளிகை',
          'tanglish': 'The Crimson Manor',
        },
        descriptionMap: {
          'en': 'Inheriting an ancestral Victorian estate seemed like a dream. Until the paintings began blinking when you walked past.',
          'ta': 'பழைய விக்டோரியன் மாளிகை சொந்தமானது ஒரு கனவு போலிருந்தது. நீங்கள் கடந்து செல்லும்போது சுவரில் உள்ள ஓவியங்கள் கண் சிமிட்டும் வரை.',
          'tanglish': 'Ancestral Victorian bungalow kedaichadhu oru dream maari irundhuchu. Aana paintings unna paathu kankalamaara varaikkum thaan.',
        },
        availableLanguages: ['en', 'ta', 'tanglish'],
        coverUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
        category: 'Horror',
        categories: ['Horror', 'Mystery', 'Supernatural'],
        creatorId: 'creator_nivetha',
        creatorName: 'Nivetha Sundar',
        creatorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&auto=format&fit=crop&q=80',
        duration: '11 min',
        plays: 89300,
        likes: 21500,
        commentsCount: 418,
        endingsCount: 5,
        startNodeId: 'cm_node_1',
        isSaved: true,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      StoryModel(
        id: 'story_neon_hearts',
        titleMap: {
          'en': 'Neon Hearts: 2099',
          'ta': 'நியோன் இதயங்கள்: 2099',
          'tanglish': 'Neon Hearts: 2099',
        },
        descriptionMap: {
          'en': 'In rain-soaked Neo-Shibuya, a cybernetic romance blossoms between a black-market memory hacker and an undercover synthetics officer.',
          'ta': 'மழை பொழியும் நியோ-ஷிபுயாவில், நினைவுகளை ஹேக் செய்பவனுக்கும் ஒரு ரகசிய துப்பறியும் பெண்ணுக்கும் இடையே மலரும் சைபர்பங்க் காதல்.',
          'tanglish': 'Rainy Neo-Shibuya-la, black-market memory hacker-kum undercover officer-kum naduvula oru cybernetic love story start aagudhu.',
        },
        availableLanguages: ['en', 'ta', 'tanglish'],
        coverUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=800&auto=format&fit=crop&q=80',
        category: 'Love',
        categories: ['Love', 'Sci-Fi', 'Cyberpunk'],
        creatorId: 'creator_tetsu',
        creatorName: 'Elena Rostova',
        creatorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80',
        duration: '10 min',
        plays: 142000,
        likes: 48900,
        commentsCount: 934,
        endingsCount: 4,
        startNodeId: 'nh_node_1',
        isSaved: false,
        isLiked: true,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      StoryModel(
        id: 'story_final_semester',
        titleMap: {
          'en': 'Final Semester Gambit',
          'ta': 'கடைசி செமஸ்டர் சாகசம்',
          'tanglish': 'Final Semester Gambit',
        },
        descriptionMap: {
          'en': '3 hours before graduation. Your dean lost the master diploma keys, and your prank squad is the only hope to rescue the ceremony.',
          'ta': 'பட்டம் பெறுவதற்கு 3 மணி நேரத்திற்கு முன், டீன் சாவிக்கொத்தை தொலைத்துவிடுகிறார். விழாவைக் காப்பாற்ற உங்கள் குறும்புக் கும்பல் மட்டுமே ஒரே நம்பிக்கை.',
          'tanglish': 'Graduation-ku innum 3 hours thaan irukku. Dean master key-a tholachitaaru, function-a kaappaatha unga prank gang thaan ore vazhi.',
        },
        availableLanguages: ['en', 'ta', 'tanglish'],
        coverUrl: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&auto=format&fit=crop&q=80',
        category: 'Comedy',
        categories: ['Comedy', 'College'],
        creatorId: 'creator_marcus',
        creatorName: 'Marcus Cole',
        creatorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
        duration: '6 min',
        plays: 67100,
        likes: 18200,
        commentsCount: 289,
        endingsCount: 4,
        startNodeId: 'fsg_node_1',
        isSaved: false,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  // Nodes for "One Last Message" with full 3-language support
  static Map<String, StoryNodeModel> getOneLastMessageNodes() {
    return {
      'olm_node_1': const StoryNodeModel(
        nodeId: 'olm_node_1',
        storyId: 'story_one_last_message',
        sceneNumber: 1,
        speakerMap: {
          'en': '11:47 PM • Dorm 402',
          'ta': 'இரவு 11:47 • விடுதி அறை 402',
          'tanglish': '11:47 PM • Dorm Room 402',
        },
        ambience: 'Thunderstorm outside',
        imageUrl: 'https://images.unsplash.com/photo-1516339901601-2e1b62dc0c45?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': '11:47 PM.\n\nRain lashes against your dorm window in jagged streaks. Your desk lamp hums quietly.\n\nSuddenly, your phone buzzes frantically across the wooden desk. A private number glows on the screen:\n\n"Unknown Number: Don\'t go home tonight."',
          'ta': 'இரவு 11:47 மணி.\n\nவிடுதி ஜன்னலில் மழை பலமாக அடிக்கிறது. மேஜை விளக்கு மெலிதாக ஒளிர்கிறது.\n\nதிடீரென, மர மேஜை மீது உங்கள் போன் அதிர்கிறது. திரையில் ஒரு தெரியாத எண் ஒளிர்கிறது:\n\n"தெரியாத எண்: இன்றிரவு வீட்டிற்குப் போகாதே."',
          'tanglish': 'Time 11:47 PM.\n\nDorm window-la mazhai thara thara-nu adikidhu. Table lamp light flickering-aa eriyudhu.\n\nThideernu, unga phone table mela bayangarama vibrate aagudhu. Screen-la oru unknown number flash aagudhu:\n\n"Unknown Number: Innaiku night veetuku pogadha."',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c1_a',
            nodeId: 'olm_node_1',
            key: 'A',
            labelMap: {
              'en': 'Answer the call immediately',
              'ta': 'உடனடியாக அழைப்பை எடு',
              'tanglish': 'Udaney call-a attend pannu',
            },
            consequenceHintMap: {
              'en': 'Hear who is behind the ominous voice',
              'ta': 'அந்த குரலுக்குப் பின்னால் யார் என்று அறி',
              'tanglish': 'Andha voice yaarnu kettu therinjukko',
            },
            nextNodeId: 'olm_node_2',
            riskLevel: 'bold',
          ),
          StoryChoiceModel(
            id: 'olm_c1_b',
            nodeId: 'olm_node_1',
            key: 'B',
            labelMap: {
              'en': 'Decline and reply: "Who is this?"',
              'ta': 'புறக்கணித்து பதில் அனுப்பு: "யார் நீங்கள்?"',
              'tanglish': 'Cut pannittu text pannu: "Yaaru pa nee?"',
            },
            consequenceHintMap: {
              'en': 'Keep a safe digital distance',
              'ta': 'பாதுகாப்பான தொலைவில் இருங்கள்',
              'tanglish': 'Safe-aa digital distance maintain pannu',
            },
            nextNodeId: 'olm_node_3',
            riskLevel: 'safe',
          ),
          StoryChoiceModel(
            id: 'olm_c1_c',
            nodeId: 'olm_node_1',
            key: 'C',
            labelMap: {
              'en': 'Ignore the warning and leave dorm now',
              'ta': 'எச்சரிக்கையை புறக்கணித்து இப்போதே வெளியேறு',
              'tanglish': 'Warning-a ignore pannittu ippove kelambu',
            },
            consequenceHintMap: {
              'en': 'Defy the message and step outside',
              'ta': 'எச்சரிக்கையை மீறி வெளியே செல்',
              'tanglish': 'Risk eduthu veliya poi paaru',
            },
            nextNodeId: 'olm_node_4',
            riskLevel: 'danger',
          ),
        ],
      ),

      'olm_node_2': const StoryNodeModel(
        nodeId: 'olm_node_2',
        storyId: 'story_one_last_message',
        sceneNumber: 2,
        speakerMap: {
          'en': 'Voice on the Line',
          'ta': 'தொலைபேசி குரல்',
          'tanglish': 'Call-la Pesura Kural',
        },
        ambience: 'Heavy static & ragged breathing',
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': 'You swipe accept and bring the cold receiver to your ear.\n\nA burst of high-pitched static crackles through, followed by a breathless, trembling whisper:\n\n"Listen carefully! They know what you discovered in the campus archives. Professor Vance\'s research wasn\'t deleted—it was buried beneath the chapel clock tower."',
          'ta': 'நீங்கள் அழைப்பை ஏற்று போனை காதில் வைக்கிறீர்கள்.\n\nஇரைச்சலுக்குப் பிறகு, ஒரு மூச்சிறைக்கும் நடுக்கமான குரல் கேட்கிறது:\n\n"கவனமாகக் கேள்! வளாக ஆவணக் காப்பகத்தில் நீ கண்டுபிடித்தது அவர்களுக்குத் தெரிந்துவிட்டது. பேராசிரியர் வேன்ஸின் ஆராய்ச்சி அழிக்கப்படவில்லை—அது தேவாலய கடிகார கோபுரத்தின் அடியில் புதைக்கப்பட்டுள்ளது."',
          'tanglish': 'Nee call-a swipe panni kaadhula vekkura.\n\nHeavy static sound-ku appram, oru padhattamaana whisper ketkudhu:\n\n"Kavanamaa kelu! Campus archives-la nee kandupidichadhu avangalukku therinjuruchu. Professor Vance research delete aagala—adhan chapel clock tower adila pudhachirukkanga!"',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c2_a',
            nodeId: 'olm_node_2',
            key: 'A',
            labelMap: {
              'en': 'Demand: "Who are you and what do you want?"',
              'ta': 'கேளுங்கள்: "யார் நீங்கள்? என்ன வேண்டும்?"',
              'tanglish': 'Kelu: "Yaaru nee? Enna venum unakku?"',
            },
            consequenceHintMap: {
              'en': 'Confront the caller on their identity',
              'ta': 'அழைத்தவரிடம் அடையாளத்தைக் கேள்',
              'tanglish': 'Call pannavan kitta direct-aa kelu',
            },
            nextNodeId: 'olm_node_5',
            riskLevel: 'bold',
          ),
          StoryChoiceModel(
            id: 'olm_c2_b',
            nodeId: 'olm_node_2',
            key: 'B',
            labelMap: {
              'en': 'Hang up and report threat to Campus Security',
              'ta': 'போனை வைத்துவிட்டு கல்லூரி பாதுகாப்பிடம் புகார் செய்',
              'tanglish': 'Cut pannittu Campus Security-ku complaint pannu',
            },
            consequenceHintMap: {
              'en': 'Trust official university authorities',
              'ta': 'அதிகாரிகளை நம்பி ஒப்படை',
              'tanglish': 'College authorities-a nambu',
            },
            endingId: 'olm_ending_1',
            riskLevel: 'safe',
          ),
          StoryChoiceModel(
            id: 'olm_c2_c',
            nodeId: 'olm_node_2',
            key: 'C',
            labelMap: {
              'en': 'Whisper the secret archive passcode: "Omega-7"',
              'ta': 'ரகசிய கடவுச்சொல்லைக் கூறு: "ஒமேகா-7"',
              'tanglish': 'Secret passcode sollu: "Omega-7"',
            },
            consequenceHintMap: {
              'en': 'Test if this caller is from the inner circle',
              'ta': 'அழைப்பவர் உண்மையானவரா என சோதி',
              'tanglish': 'Call pannavan genuine-aa nu test pannu',
            },
            nextNodeId: 'olm_node_8',
            riskLevel: 'secret',
          ),
        ],
      ),

      'olm_node_3': const StoryNodeModel(
        nodeId: 'olm_node_3',
        storyId: 'story_one_last_message',
        sceneNumber: 2,
        speakerMap: {
          'en': 'Encrypted SMS',
          'ta': 'மறைகுறியாக்கப்பட்ட குறுஞ்செய்தி',
          'tanglish': 'Encrypted SMS',
        },
        ambience: 'Eerie silence',
        imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': 'You reject the call and type: "Wrong number."\n\nWithin three seconds, your screen flashes. An incoming attachment arrives:\n\nA photo taken 10 seconds ago of your dorm door from out in the hallway.\n\nCaption: "Too late. Look through the peephole."',
          'ta': 'அழைப்பைத் துண்டித்துவிட்டு, "தவறான எண்" என்று அனுப்புகிறீர்கள்.\n\nமூன்றே வினாடிகளில் உங்கள் திரை ஒளிர்கிறது. ஒரு புகைப்படம் வருகிறது:\n\n10 வினாடிகளுக்கு முன் உங்கள் கதவின் வெளிப்புறம் எடுக்கப்பட்ட புகைப்படம்.\n\nகுறிப்பு: "தாமதமாகிவிட்டது. கதவின் துளை வழியே பார்."',
          'tanglish': 'Call-a cut pannittu "Wrong number"-nu type panra.\n\nNext 3 seconds-la screen flash aagi oru photo varudhu:\n\n10 seconds munnadi un dorm door velila irundhu edutha photo!\n\nCaption: "Too late. Peephole vazhiya paaru."',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c3_a',
            nodeId: 'olm_node_3',
            key: 'A',
            labelMap: {
              'en': 'Deadbolt the door and barricade with desk',
              'ta': 'கதவைப் பூட்டி மேஜையை வைத்து அடை',
              'tanglish': 'Door-a lock panni table vechu block pannu',
            },
            consequenceHintMap: {
              'en': 'Fortify your room until daylight',
              'ta': 'விடியும் வரை அறையை பலப்படுத்து',
              'tanglish': 'Kaalaila varaikkum room-a lock pannu',
            },
            endingId: 'olm_ending_2',
            riskLevel: 'safe',
          ),
          StoryChoiceModel(
            id: 'olm_c3_b',
            nodeId: 'olm_node_3',
            key: 'B',
            labelMap: {
              'en': 'Creep to the door and look through peephole',
              'ta': 'மெதுவாகச் சென்று கதவின் துளை வழியே பார்',
              'tanglish': 'Silent-aa poi peephole vazhiya paaru',
            },
            consequenceHintMap: {
              'en': 'Face the stalker directly',
              'ta': 'வந்திருப்பவரை நேரில் பார்',
              'tanglish': 'Ninnutu irukkura aala direct-aa paaru',
            },
            nextNodeId: 'olm_node_6',
            riskLevel: 'danger',
          ),
        ],
      ),

      'olm_node_4': const StoryNodeModel(
        nodeId: 'olm_node_4',
        storyId: 'story_one_last_message',
        sceneNumber: 2,
        speakerMap: {
          'en': '4th Floor Corridor',
          'ta': '4வது மாடி தாழ்வாரம்',
          'tanglish': '4th Floor Corridor',
        },
        ambience: 'Buzzing neon & distant footfalls',
        imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': 'You grab your coat and step out into the hallway.\n\nThe instant the latch clicks shut, the fluorescent ceiling strips flicker wildly and buzz dead. Total darkness.\n\nThen, from the end of the stairwell: slow, deliberate footsteps clicking against the floor.',
          'ta': 'மேலாடையை எடுத்துக்கொண்டு தாழ்வாரத்தில் இறங்குகிறீர்கள்.\n\nகதவு மூடிய அடுத்த கணம், கூரை விளக்குகள் படபடத்து முற்றிலும் அணைகின்றன. இருள் சூழ்ந்தது.\n\nபடிக்கட்டு முனையிலிருந்து மெதுவான, உறுதியான காலடி சத்தம் எதிரொலிக்கிறது.',
          'tanglish': 'Coat-a maatitu corridor-ku veliya varra.\n\nDoor latch lock aana udaney, ceiling lights flicker aagi total-aa off aayiduchu. Full pitch dark.\n\nAppo stairwell pakkathula irundhu slow-aa oru footsteps sound ketkudhu.',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c4_a',
            nodeId: 'olm_node_4',
            key: 'A',
            labelMap: {
              'en': 'Sprint for the outdoor emergency fire escape',
              'ta': 'தீயணைப்பு அவசர படிக்கட்டு நோக்கி ஓடு',
              'tanglish': 'Fire escape stairway நோக்கி வேகமா ஓடு',
            },
            consequenceHintMap: {
              'en': 'Escape into the torrential night',
              'ta': 'மழையில் தப்பித்துச் செல்',
              'tanglish': 'Mazhaila thappichu odu',
            },
            endingId: 'olm_ending_3',
            riskLevel: 'danger',
          ),
          StoryChoiceModel(
            id: 'olm_c4_b',
            nodeId: 'olm_node_4',
            key: 'B',
            labelMap: {
              'en': 'Slip into the abandoned faculty study lounge',
              'ta': 'கைவிடப்பட்ட பேராசிரியர் அறைக்குள் பதுங்கு',
              'tanglish': 'Abandoned faculty lounge-kulla oli',
            },
            consequenceHintMap: {
              'en': 'Hide among forgotten university relics',
              'ta': 'பழைய வரலாற்றுப் பொருட்களுக்குள் ஒளிந்து கொள்',
              'tanglish': 'Old things naduvula oli',
            },
            nextNodeId: 'olm_node_7',
            riskLevel: 'bold',
          ),
        ],
      ),

      'olm_node_5': const StoryNodeModel(
        nodeId: 'olm_node_5',
        storyId: 'story_one_last_message',
        sceneNumber: 3,
        speakerMap: {
          'en': 'Encrypted Terminal',
          'ta': 'மறைகுறியீட்டு கணினி',
          'tanglish': 'Hacked Laptop Screen',
        },
        ambience: 'Whirring fans & electrical hum',
        imageUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': '"Doesn\'t matter who I am," the caller snaps, their breath hitching.\n\nAcross the room, your closed laptop suddenly wakes up. The fans spin to maximum velocity. Lines of emerald terminal code stream down the screen:\n\n"UPLOADING TELEMETRY: ST. JUDE CLOCKTOWER RELAY // 94% COMPLETE"',
          'ta': '"நான் யார் என்பது முக்கியமில்லை," குரல் கூறுகிறது.\n\nஅறையின் மறுபுறம் மூடியிருந்த உங்கள் மடிக்கணினி தானாகவே ஒளிர்கிறது. விசிறிகள் வேகமாக சுழல்கின்றன. பச்சை நிறக் குறியீடுகள் திரையில் வழிகின்றன:\n\n"பதிவேற்றம் நடக்கிறது: கடிகார கோபுர இணைப்பு // 94% நிறைவு"',
          'tanglish': '"Naan yaarnu mukkiyam illa," call-la irukkuravan solraan.\n\nRoom-la closed-aa irundha laptop thideernu on aagudhu. Fans maximum speed-la suzhaludhu. Green code stream aagudhu:\n\n"UPLOADING DATA: CLOCKTOWER RELAY // 94% FINISHED"',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c5_a',
            nodeId: 'olm_node_5',
            key: 'A',
            labelMap: {
              'en': 'Yank out the power cord and smash the hard drive',
              'ta': 'மின் இணைப்பைத் துண்டித்து தகவலை அழி',
              'tanglish': 'Power cable-a pudungitu hard drive-a uda',
            },
            consequenceHintMap: {
              'en': 'Erase all digital traces immediately',
              'ta': 'அனைத்து டிஜிட்டல் தடங்களையும் அழி',
              'tanglish': 'Ellaa digital traces-aiyum erase pannu',
            },
            endingId: 'olm_ending_4',
            riskLevel: 'safe',
          ),
          StoryChoiceModel(
            id: 'olm_c5_b',
            nodeId: 'olm_node_5',
            key: 'B',
            labelMap: {
              'en': 'Allow upload to finish and trace destination IP',
              'ta': 'பதிவேற்றத்தை அனுமதித்து மூலத்தைத் தேடு',
              'tanglish': 'Upload aaga vittu destination trace pannu',
            },
            consequenceHintMap: {
              'en': 'Follow the digital breadcrumb to the core',
              'ta': 'தகவலின் இறுதி மூலத்தைக் கண்டுபிடி',
              'tanglish': 'Main destination-a kandupidi',
            },
            nextNodeId: 'olm_node_8',
            riskLevel: 'secret',
          ),
        ],
      ),

      'olm_node_6': const StoryNodeModel(
        nodeId: 'olm_node_6',
        storyId: 'story_one_last_message',
        sceneNumber: 3,
        speakerMap: {
          'en': 'The Peephole',
          'ta': 'கதவு துளை',
          'tanglish': 'Peephole View',
        },
        ambience: 'Muffled whispers outside',
        imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': 'You press your brow against the cold brass.\n\nStanding under the amber emergency bulb is Professor Vance\'s teaching assistant, Devon. His face is pale as salt. In his trembling hands is a sealed black folder stamped with the University Seal.\n\n"Please open up," Devon whimpers. "They\'re wiping everyone who knows!"',
          'ta': 'குளிர்ந்த துளையில் கண்களை வைத்துப் பார்க்கிறீர்கள்.\n\nபேராசிரியர் வேன்ஸின் உதவியாளர் டெவன் நிற்கிறார். அவர் முகம் பயத்தில் வெளிறியுள்ளது. கைகளில் பல்கலைக்கழக முத்திரை பதித்த கருப்பு கோப்பு.\n\n"தயவுசெய்து கதவைத் திற," டெவன் நடுங்குகிறார். "உண்மை தெரிந்த அனைவரையும் அழிக்கிறார்கள்!"',
          'tanglish': 'Brass peephole-la kanna vechu paakkura.\n\nAnga Professor Vance assistant Devon nikiraan. Bayathula mugamey maaripirukku. Kayila oru black sealed file vechurukkaan.\n\n"Please door-a thora!" Devon whisper panraan. "Therinjavan ellathayum wipe panraanga!"',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c6_a',
            nodeId: 'olm_node_6',
            key: 'A',
            labelMap: {
              'en': 'Unlock the door and pull Devon inside',
              'ta': 'கதவைத் திறந்து டெவனை உள்ளே இழு',
              'tanglish': 'Door-a thirandhu Devon-a ulluka izhu',
            },
            consequenceHintMap: {
              'en': 'Accept the confidential evidence',
              'ta': 'ரகசிய ஆதாரத்தை ஏற்றுக்கொள்',
              'tanglish': 'Secret file-a vaangikko',
            },
            endingId: 'olm_ending_1',
            riskLevel: 'bold',
          ),
          StoryChoiceModel(
            id: 'olm_c6_b',
            nodeId: 'olm_node_6',
            key: 'B',
            labelMap: {
              'en': 'Don\'t open. Leap from the balcony fire ladder',
              'ta': 'திறக்காதே. பால்கனி வழியே தப்பி ஓடு',
              'tanglish': 'Thirakkadha. Balcony fire ladder vazhiya thappichu odu',
            },
            consequenceHintMap: {
              'en': 'Trust no one on campus',
              'ta': 'வளாகத்தில் யாரையும் நம்பாதே',
              'tanglish': 'Yaarayum nambama thappi',
            },
            endingId: 'olm_ending_3',
            riskLevel: 'danger',
          ),
        ],
      ),

      'olm_node_7': const StoryNodeModel(
        nodeId: 'olm_node_7',
        storyId: 'story_one_last_message',
        sceneNumber: 3,
        speakerMap: {
          'en': 'Forgotten Archives',
          'ta': 'மறைக்கப்பட்ட ஆவணம்',
          'tanglish': 'Secret Room',
        },
        ambience: 'Old book smell & low vibration',
        imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': 'You dive behind the heavy oak bookcases of the study lounge. The pursuer\'s heavy boots stride past the doorway outside.\n\nAs your shoulder presses against the mahogany wainscoting, an ancient concealed latch clicks. A section of the wall slides back into a subterranean chamber glowing with warm amber vacuum tubes.',
          'ta': 'மர அலமாரிகளுக்குப் பின்னால் பதுங்குகிறீர்கள். துரத்தி வந்தவரின் காலடி சத்தம் தாண்டிச் செல்கிறது.\n\nஉங்கள் தோள் சுவரில் அழுத்தும்போது, ஒரு ரகசிய பூட்டு திறக்கிறது. சுவர் நகர்ந்து விளக்குகள் ஒளிரும் நிலத்தடி அறைக்குள் வழிவிடுகிறது.',
          'tanglish': 'Periya book shelf pinnadi poi oliyura. Veliya andha aalu cross aagi poran.\n\nUnga shoulder wall-la patta udaney, oru secret latch click aagudhu. Wall slide aagi, amber light eriyura secret room thirakkudhu.',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c7_a',
            nodeId: 'olm_node_7',
            key: 'A',
            labelMap: {
              'en': 'Inspect the glowing vintage radio terminal',
              'ta': 'ஒளிரும் வானொலி முனையத்தை ஆய்வு செய்',
              'tanglish': 'Glowing vintage radio terminal-a check pannu',
            },
            consequenceHintMap: {
              'en': 'Decode the secret broadcast',
              'ta': 'ரகசிய ஒலிபரப்பைத் தீர்த்து அறி',
              'tanglish': 'Secret transmission-a decode pannu',
            },
            nextNodeId: 'olm_node_8',
            riskLevel: 'secret',
          ),
          StoryChoiceModel(
            id: 'olm_c7_b',
            nodeId: 'olm_node_7',
            key: 'B',
            labelMap: {
              'en': 'Stay silent in the shadows until sunrise',
              'ta': 'விடியும் வரை நிழலில் அமைதியாக இரு',
              'tanglish': 'Kaalaila varaikkum silent-aa anga iru',
            },
            consequenceHintMap: {
              'en': 'Prioritize physical safety',
              'ta': 'பாதுகாப்புக்கு முன்னுரிமை கொடு',
              'tanglish': 'Uyirodu irukka silent-aa iru',
            },
            endingId: 'olm_ending_2',
            riskLevel: 'safe',
          ),
        ],
      ),

      'olm_node_8': const StoryNodeModel(
        nodeId: 'olm_node_8',
        storyId: 'story_one_last_message',
        sceneNumber: 4,
        speakerMap: {
          'en': 'Temporal Relay • Core Node',
          'ta': 'கால அலைவரிசை மையம்',
          'tanglish': 'Future Transmission Core',
        },
        ambience: 'Resonating chime & crystalline harmony',
        imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&auto=format&fit=crop&q=80',
        textMap: {
          'en': 'The frequencies align with a deafening ring.\n\nA synthesizer voice broadcasts from the receiver:\n\n"TRANSMISSION TIMESTAMP: 24 HOURS IN THE FUTURE. SENDER: YOU."\n\nThe final puzzle piece falls into place. The unknown caller was never an enemy. It was your future self, caught in a recursive time loop created by Vance\'s temporal antenna on the clock tower, trying to warn you before the cycle repeats!',
          'ta': 'அலைவரிசைகள் ஒத்திசைகின்றன.\n\nவானொலியிலிருந்து ஒரு குரல் ஒலிக்கிறது:\n\n"செய்தி அனுப்பப்பட்ட நேரம்: 24 மணிநேரம் எதிர்காலம். அனுப்பியவர்: நீயேதான்."\n\nபுதிர் அவிழ்ந்தது. அந்த தெரியாத அழைப்பாளர் எதிரி அல்ல. கடிகார கோபுர அலைவரிசையால் உருவான கால சுழற்சியில் சிக்கிய உன் எதிர்கால சுயமே, இந்த சுழற்சியை உடைக்க எச்சரித்தது!',
          'tanglish': 'Frequencies synchronize aagi oru ring sound varudhu.\n\nReceiver-la irundhu voice pesudhu:\n\n"MESSAGE TIME: 24 HOURS FUTURE-LA IRUNDHU. SENDER: NEEYE THAAN."\n\nFinal puzzle solve aayiduchu! Unknown caller enemy kidayadhu. Vance clock tower machine-la maattuna un future self thaan, indha recursive time loop-a break panna unakku call pannirukkaan!',
        },
        choices: [
          StoryChoiceModel(
            id: 'olm_c8_a',
            nodeId: 'olm_node_8',
            key: 'A',
            labelMap: {
              'en': 'Broadcast the Paradox Cancellation Override',
              'ta': 'கால முரண்பாட்டு ரத்து அலைவரிசையை ஒலிபரப்பு',
              'tanglish': 'Paradox Cancellation code-a broadcast pannu',
            },
            consequenceHintMap: {
              'en': 'Break the temporal loop once and for all',
              'ta': 'கால சுழற்சியை நிரந்தரமாக உடைத்து விடு',
              'tanglish': 'Time loop-a permanently break pannu',
            },
            endingId: 'olm_ending_secret',
            riskLevel: 'secret',
          ),
          StoryChoiceModel(
            id: 'olm_c8_b',
            nodeId: 'olm_node_8',
            key: 'B',
            labelMap: {
              'en': 'Disconnect the transmitter to preserve the timeline',
              'ta': 'காலக்கோட்டைப் பாதுகாக்க இணைப்பைத் துண்டி',
              'tanglish': 'Timeline-a preserve panna transmitter-a off pannu',
            },
            consequenceHintMap: {
              'en': 'Bury the technology forever',
              'ta': 'தொழில்நுட்பத்தை என்றென்றைக்கும் மறைத்துவிடு',
              'tanglish': 'Indha secret-a appadiye maraichiru',
            },
            endingId: 'olm_ending_4',
            riskLevel: 'bold',
          ),
        ],
      ),
    };
  }

  // Endings for "One Last Message" with full 3-language support
  static Map<String, StoryEndingModel> getOneLastMessageEndings() {
    return {
      'olm_ending_1': const StoryEndingModel(
        id: 'olm_ending_1',
        storyId: 'story_one_last_message',
        titleMap: {
          'en': 'The Academic Conspiracy',
          'ta': 'கல்வித்துறை சதி',
          'tanglish': 'College Conspiracy',
        },
        descriptionMap: {
          'en': 'Campus authorities and the Board arrive before dawn. The evidence is sealed behind closed doors, your scholarship is quietly enhanced, and Professor Vance\'s life work is expunged from all historical records.',
          'ta': 'விடிவதற்குள் கல்லூரி நிர்வாகம் வருகிறது. ஆதாரங்கள் முடக்கப்பட்டு, உங்கள் உதவித்தொகை உயர்த்தப்பட்டு, வேன்ஸின் ஆராய்ச்சி வரலாற்றிலிருந்து அழிக்கப்படுகிறது.',
          'tanglish': 'Morning-kulla college authorities vandhutaanga. Evidence ellaam lock pannittu, un scholarship-a perusaakki, Vance research-a history-la irundhey delete pannitaanga.',
        },
        imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop&q=80',
        rarity: 'Common',
        rarityPercentage: 38.4,
        isSecret: false,
        badgeIcon: '📜',
      ),
      'olm_ending_2': const StoryEndingModel(
        id: 'olm_ending_2',
        storyId: 'story_one_last_message',
        titleMap: {
          'en': 'Surviving The Night',
          'ta': 'இரவைக் கடந்து தப்பித்தல்',
          'tanglish': 'Surviving The Night',
        },
        descriptionMap: {
          'en': 'You kept your door barricaded until morning sunlight illuminated the campus quad. You survived completely unscathed, but every time your phone rings after midnight, a chill runs down your spine.',
          'ta': 'காலை வெளிச்சம் வரும் வரை நீங்கள் கதவை அடைத்து தப்பித்தீர்கள். நீங்கள் காயமின்றி பிழைத்தாலும், நள்ளிரவில் போன் ஒலிக்கும் போதெல்லாம் நடுக்கம் ஏற்படுகிறது.',
          'tanglish': 'Kaalaila velicham varra varaikkum door-a thirakkave illa. Uyiroda thappichitta, aana innum midnight call vandha goosebumps aagudhu.',
        },
        imageUrl: 'https://images.unsplash.com/photo-1516339901601-2e1b62dc0c45?w=800&auto=format&fit=crop&q=80',
        rarity: 'Uncommon',
        rarityPercentage: 29.1,
        isSecret: false,
        badgeIcon: '🛡️',
      ),
      'olm_ending_3': const StoryEndingModel(
        id: 'olm_ending_3',
        storyId: 'story_one_last_message',
        titleMap: {
          'en': 'The Midnight Chase',
          'ta': 'நள்ளிரவு துரத்தல்',
          'tanglish': 'Midnight Chase',
        },
        descriptionMap: {
          'en': 'You sprinted through the rainstorm into the city underbelly, outrunning the shadows. You left your old identity behind, living off the grid with a thumbdrive of secrets worth millions.',
          'ta': 'மழையில் ஓடி நகருக்குள் மறைந்துவிட்டீர்கள். நிழல் மனிதர்களிடமிருந்து தப்பி, பல கோடி மதிப்புள்ள ரகசியங்களோடு அடையாளமின்றி வாழ்கிறீர்கள்.',
          'tanglish': 'Mazhaila fast-aa escape aagi city-kulla maranjitta. Shadows-la irundhu thappichu, million dollar secret-oda off-the-grid vazhura.',
        },
        imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80',
        rarity: 'Rare',
        rarityPercentage: 18.3,
        isSecret: false,
        badgeIcon: '⚡',
      ),
      'olm_ending_4': const StoryEndingModel(
        id: 'olm_ending_4',
        storyId: 'story_one_last_message',
        titleMap: {
          'en': 'The Digital Ghost',
          'ta': 'டிஜிட்டல் பேய்',
          'tanglish': 'Digital Ghost',
        },
        descriptionMap: {
          'en': 'By disconnecting the telemetry network, you severed the link between St. Jude and the clandestine syndicate. The secret was saved, but you became a phantom erased from the university database.',
          'ta': 'இணைப்பைத் துண்டித்ததால் உங்கள் விவரங்கள் அழிக்கப்பட்டன. பேரழிவு தடுக்கப்பட்டது, ஆனால் பல்கலைக்கழக ஆவணங்களிலிருந்து நீக்கப்பட்ட ஒரு டிஜிட்டல் பேயாக மாறினீர்கள்.',
          'tanglish': 'Network-a cut panni un identity-aye database-la irundhu erase pannitta. Problem solve aanaalum, nee ippo oru digital ghost.',
        },
        imageUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&auto=format&fit=crop&q=80',
        rarity: 'Rare',
        rarityPercentage: 10.0,
        isSecret: false,
        badgeIcon: '💾',
      ),
      'olm_ending_secret': const StoryEndingModel(
        id: 'olm_ending_secret',
        storyId: 'story_one_last_message',
        titleMap: {
          'en': 'THE TRUTH: LOOP BROKEN',
          'ta': 'உண்மை: கால சுழற்சி உடைந்தது',
          'tanglish': 'THE TRUTH: TIME LOOP BROKEN',
        },
        descriptionMap: {
          'en': '⭐ SECRET ENDING: You transmitted the exact paradox cancellation frequency into the clock tower antenna! The 24-hour time loop shattered, the truth was published globally, and for the first time, tomorrow arrived.',
          'ta': '⭐ ரகசிய முடிவு: சரியான ரத்து அலைவரிசையை அனுப்பினீர்கள்! 24 மணிநேர சுழற்சி உடைந்து, உண்மை உலகம் முழுவதும் பரவியது. இறுதியாக ஒரு புதிய விடியல் பிறந்தது.',
          'tanglish': '⭐ SECRET ENDING: Correct cancellation code-a send pannita! Andha 24-hour loop totally break aagi, unmai world full-aa therinjuruchu. Finally naalaiki-nu oru naal vandhuchu!',
        },
        imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&auto=format&fit=crop&q=80',
        rarity: 'Secret',
        rarityPercentage: 4.2,
        isSecret: true,
        badgeIcon: '👑',
      ),
    };
  }

  // Activities
  static List<ActivityModel> getActivities() {
    return [
      ActivityModel(
        id: 'act_1',
        type: 'achievement',
        title: 'Secret Ending Finder',
        subtitle: 'You unlocked the secret ending in "One Last Message"! Only 4.2% found this.',
        storyTitle: 'One Last Message',
        targetEndingId: 'olm_ending_secret',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ActivityModel(
        id: 'act_2',
        type: 'challenge',
        title: 'Kavin challenged you',
        subtitle: '"Same story. Different choice. Can you find Ending #4?"',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&auto=format&fit=crop&q=80',
        storyId: 'story_one_last_message',
        storyTitle: 'One Last Message',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ActivityModel(
        id: 'act_3',
        type: 'like',
        title: 'Kavin liked your story',
        subtitle: 'Kavin and 42 others liked your decision in Scene 3.',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&auto=format&fit=crop&q=80',
        storyTitle: 'One Last Message',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ActivityModel(
        id: 'act_4',
        type: 'follow',
        title: 'Nivetha started following you',
        subtitle: 'Follow back to see their new horror stories.',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&auto=format&fit=crop&q=80',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      ActivityModel(
        id: 'act_5',
        type: 'milestone',
        title: '10K Plays Milestone',
        subtitle: 'Your shared story branch reached 10K plays in the community feed!',
        storyTitle: 'One Last Message',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Comments for "One Last Message"
  static List<CommentModel> getSampleComments(String storyId) {
    return [
      CommentModel(
        id: 'c_1',
        storyId: storyId,
        userId: 'u_sarah',
        userName: 'Sarah Jenkins',
        userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80',
        text: 'NO WAY!! When I chose Option C in Scene 2 I screamed out loud!! That plot twist with Devon was insane 🤯',
        likes: 124,
        isLiked: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CommentModel(
        id: 'c_2',
        storyId: storyId,
        userId: 'u_david',
        userName: 'David Chen',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
        text: 'Has anyone found the secret ending yet? I am on my 4th replay trying to crack the temporal code.',
        likes: 47,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      CommentModel(
        id: 'c_3',
        storyId: storyId,
        userId: 'u_maya',
        userName: 'Maya Sharma',
        userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
        text: 'The sound design and pacing in the corridor scene gave me genuine chills. TWIST stories are next level!',
        likes: 89,
        isLiked: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
