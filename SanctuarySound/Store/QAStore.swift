// ============================================================================
// QAStore.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Store Layer
// Purpose: Loads and manages the Sound Engineer Q&A knowledge base.
//          Reads bundled JSON content, provides search and filtering,
//          and publishes results for the QABrowserView.
// ============================================================================

import Foundation


// MARK: - ─── QA Store ────────────────────────────────────────────────────────

/// Manages the Q&A knowledge base — loading, searching, and filtering articles.
@MainActor
final class QAStore: ObservableObject {

    // ── Published State ──
    @Published private(set) var articles: [QAArticle] = []
    @Published var searchQuery: String = ""
    @Published var selectedCategory: QACategory?
    @Published var selectedDifficulty: QADifficulty?

    /// Filtered articles based on current search/filter state.
    var filteredArticles: [QAArticle] {
        var results = articles

        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            results = results.filter { $0.difficulty == difficulty }
        }

        // Search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            results = results.filter { article in
                article.title.lowercased().contains(query)
                || article.summary.lowercased().contains(query)
                || article.tags.contains { $0.lowercased().contains(query) }
                || article.sections.contains { section in
                    section.content.lowercased().contains(query)
                    || (section.heading?.lowercased().contains(query) ?? false)
                }
            }
        }

        return results
    }

    /// Articles grouped by category (for browse view).
    var articlesByCategory: [QACategory: [QAArticle]] {
        Dictionary(grouping: articles, by: { $0.category })
    }

    /// Count of articles per category.
    func articleCount(for category: QACategory) -> Int {
        articles.filter { $0.category == category }.count
    }

    /// Find related articles for a given article.
    func relatedArticles(for article: QAArticle) -> [QAArticle] {
        article.relatedArticles.compactMap { relatedID in
            articles.first { $0.id == relatedID }
        }
    }


    // MARK: - ─── Loading ─────────────────────────────────────────────────────

    /// Load articles from the bundled JSON file.
    func loadContent() {
        guard let url = Bundle.main.url(forResource: "qa_content", withExtension: "json") else {
            // If no JSON file, load built-in content
            articles = Self.builtInArticles
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([QAArticle].self, from: data)
            articles = decoded
        } catch {
            // Fallback to built-in content
            articles = Self.builtInArticles
        }
    }


    // MARK: - ─── Built-In Content ────────────────────────────────────────────

    /// Hardcoded starter articles — used as fallback if JSON bundle is missing.
    static let builtInArticles: [QAArticle] = [

        // ── Gain Staging ──
        QAArticle(
            id: "gain-staging-basics",
            title: "What Is Gain Staging?",
            category: .gainStaging,
            difficulty: .beginner,
            summary: "Learn why proper gain staging is the foundation of a good mix and how to set your preamp levels correctly.",
            sections: [
                QASection(
                    heading: "Why It Matters",
                    content: "Gain staging is the process of setting the right signal level at each point in the audio chain. Too low, and you get hiss and noise. Too high, and you get distortion and clipping. The goal is to hit the 'sweet spot' where the signal is clean and strong.",
                    tip: "On digital consoles, aim for your signal to sit around -18 dBFS on the meter. This gives you 18 dB of headroom before clipping."
                ),
                QASection(
                    heading: "Setting the Preamp",
                    content: "Have the vocalist sing at their loudest expected level during soundcheck. Slowly bring up the gain until the meter reads around -18 dBFS on the loudest peaks. The meter should bounce comfortably without hitting the red. Once gain is set, use the fader for mix balance — don't touch the gain knob during service.",
                    tip: "A common mistake is setting gain too hot during soundcheck when people are quiet, then getting surprised when the band plays full volume."
                ),
                QASection(
                    heading: "The Gain-Fader Relationship",
                    content: "Think of gain as 'how loud is the raw signal' and fader as 'how loud do I want this in the mix.' Gain is set once during soundcheck. Faders are used throughout the service to balance the mix. If you find yourself pushing a fader above unity (0 dB), your gain might be too low.",
                    tip: nil
                )
            ],
            tags: ["gain", "preamp", "levels", "meters", "clipping", "noise", "headroom"],
            relatedArticles: ["why-is-there-hiss", "what-does-pad-do"]
        ),

        QAArticle(
            id: "why-is-there-hiss",
            title: "Why Is There Hiss in My Mix?",
            category: .gainStaging,
            difficulty: .beginner,
            summary: "Common causes of hiss and background noise, and how to eliminate them by fixing your gain structure.",
            sections: [
                QASection(
                    heading: "Low Gain, High Fader",
                    content: "The most common cause of hiss is setting the preamp gain too low and compensating with a high fader level. When you amplify a quiet signal, you also amplify the noise floor. The fix: bring the gain up until the signal reads around -18 dBFS, then bring the fader back down.",
                    tip: "If the fader is above +5 dB and you hear hiss, your gain is almost certainly too low."
                ),
                QASection(
                    heading: "Cable and Connection Issues",
                    content: "Bad XLR cables, loose connections, and unbalanced runs over long distances can introduce noise. Check your cables by swapping them one at a time. Use balanced cables for all runs over 15 feet.",
                    tip: nil
                ),
                QASection(
                    heading: "Phantom Power Issues",
                    content: "Condenser mics need 48V phantom power. If a condenser mic sounds noisy or weak, check that phantom power is enabled on that channel. Conversely, some ribbon mics can be damaged by phantom power — always check your mic type.",
                    tip: nil
                )
            ],
            tags: ["hiss", "noise", "gain", "troubleshooting", "cables"],
            relatedArticles: ["gain-staging-basics"]
        ),

        QAArticle(
            id: "what-does-pad-do",
            title: "What Does the PAD Button Do?",
            category: .gainStaging,
            difficulty: .intermediate,
            summary: "Understanding when and why to use the PAD switch on your console's preamp.",
            sections: [
                QASection(
                    heading: "What Is a PAD?",
                    content: "The PAD button attenuates (reduces) the incoming signal by a fixed amount, typically 20 dB. It's used when a source is so loud that even with the gain knob at minimum, the signal is still clipping.",
                    tip: "Common scenario: a keyboard sending line-level (+4 dBu) into a mic-level input. The PAD brings it down to a manageable level."
                ),
                QASection(
                    heading: "When to Use It",
                    content: "Use the PAD when: the gain knob is at its lowest setting and the signal is still too hot, you're receiving a line-level signal into a mic input, or a drummer is hitting incredibly hard on a close-miked drum. You generally don't need PAD for normal vocal mics.",
                    tip: nil
                )
            ],
            tags: ["pad", "gain", "preamp", "line level", "hot signal"],
            relatedArticles: ["gain-staging-basics"]
        ),

        // ── EQ Basics ──
        QAArticle(
            id: "muddy-frequencies",
            title: "What Frequencies Are 'Muddy'?",
            category: .eq,
            difficulty: .beginner,
            summary: "Learn to identify and tame the 200-500 Hz range that causes muddy, unclear mixes.",
            sections: [
                QASection(
                    heading: "The Mud Zone",
                    content: "The frequency range from roughly 200 Hz to 500 Hz is where 'mud' lives. When multiple instruments pile up energy in this range, the mix sounds thick, boomy, and unclear. Almost every source has content here — vocals, guitars, keys, drums — so it builds up fast.",
                    tip: "A 3 dB cut at 300 Hz on several channels can dramatically clean up your overall mix."
                ),
                QASection(
                    heading: "How to Fix It",
                    content: "Use a parametric EQ to make gentle cuts (2-4 dB) in the 200-500 Hz range on channels that don't need low-mid body. Acoustic guitar, keyboards, and backing vocals are good candidates for low-mid cuts. Leave the low-mid content on bass guitar, kick drum, and the lead vocal — they need it for warmth.",
                    tip: "Cut mud on everything except the instruments that own that frequency range."
                ),
                QASection(
                    heading: "Subtractive EQ Philosophy",
                    content: "Instead of boosting frequencies you want more of, cut the frequencies you want less of. Cutting is almost always better than boosting — it sounds more natural, uses less headroom, and is less likely to cause feedback.",
                    tip: nil
                )
            ],
            tags: ["mud", "eq", "250hz", "300hz", "low-mid", "clarity"],
            relatedArticles: ["reduce-harshness", "subtractive-vs-additive"]
        ),

        QAArticle(
            id: "reduce-harshness",
            title: "How Do I Reduce Harshness?",
            category: .eq,
            difficulty: .intermediate,
            summary: "Taming the 2-5 kHz range to reduce ear fatigue and harsh, piercing sounds.",
            sections: [
                QASection(
                    heading: "The Harshness Zone",
                    content: "Frequencies between 2 kHz and 5 kHz are where harshness and 'ear fatigue' live. Our ears are most sensitive in this range (it's where speech consonants sit), so even small peaks here sound very aggressive. Cymbals, distorted guitars, and sibilant vocals are common offenders.",
                    tip: "Sweep a narrow EQ boost through 2-5 kHz to find the exact offending frequency, then cut it by 2-4 dB."
                ),
                QASection(
                    heading: "De-Essing Vocals",
                    content: "If vocals sound sibilant (harsh 'S' and 'T' sounds), you can use a narrow EQ cut around 5-8 kHz or, if your console has one, a de-esser. A 2-3 dB cut with a medium-narrow Q at the sibilant frequency usually does the trick.",
                    tip: nil
                )
            ],
            tags: ["harshness", "sibilance", "ear fatigue", "eq", "2khz", "presence"],
            relatedArticles: ["muddy-frequencies"]
        ),

        QAArticle(
            id: "subtractive-vs-additive",
            title: "Subtractive vs Additive EQ",
            category: .eq,
            difficulty: .intermediate,
            summary: "Why cutting frequencies is almost always better than boosting, and when boosting is appropriate.",
            sections: [
                QASection(
                    heading: "Subtractive EQ (Cutting)",
                    content: "Removing unwanted frequencies is the foundation of good EQ practice. Cuts sound natural, reduce the chance of feedback, preserve headroom, and can be more aggressive without sounding bad. Most of your EQ moves should be cuts.",
                    tip: "A good starting approach: HPF to remove rumble, cut the mud zone (200-400 Hz), and cut any harsh resonances."
                ),
                QASection(
                    heading: "When to Boost",
                    content: "Boosting is appropriate for adding 'air' (subtle +2 dB shelf above 10 kHz), adding presence to a vocal (+1-2 dB around 3-4 kHz), or brightening a dull source. Keep boosts gentle — under +3 dB is ideal. Large boosts often indicate a problem that should be fixed at the source.",
                    tip: nil
                )
            ],
            tags: ["eq", "subtractive", "additive", "boost", "cut", "technique"],
            relatedArticles: ["muddy-frequencies", "reduce-harshness"]
        ),

        // ── Compression ──
        QAArticle(
            id: "what-does-compressor-do",
            title: "What Does a Compressor Do?",
            category: .compression,
            difficulty: .beginner,
            summary: "Understanding dynamic range compression — making quiet parts louder and loud parts quieter.",
            sections: [
                QASection(
                    heading: "The Basic Idea",
                    content: "A compressor automatically reduces the volume when the signal gets too loud. This evens out the dynamic range — the difference between the quietest and loudest moments. For vocals, this means the whispered verse and the belted chorus sit at more consistent levels in the mix.",
                    tip: "Think of a compressor as an automatic hand on the fader, turning it down when things get loud."
                ),
                QASection(
                    heading: "Key Controls",
                    content: "Threshold: the level at which compression kicks in. Ratio: how much the signal is reduced (2:1 means for every 2 dB over threshold, only 1 dB comes through). Attack: how quickly compression engages. Release: how quickly it lets go. Start with gentle settings: -20 dB threshold, 2:1 ratio, 10ms attack, 100ms release.",
                    tip: nil
                ),
                QASection(
                    heading: "When to Use It",
                    content: "Compression is most useful on vocals (evening out dynamics), bass guitar (consistent low end), and drum overheads (controlling cymbal peaks). For church sound, keep ratios between 2:1 and 4:1 — aggressive compression (above 4:1) can cause pumping artifacts that sound unnatural.",
                    tip: "If you can hear the compressor working, it's probably too aggressive. Good compression should be invisible."
                )
            ],
            tags: ["compressor", "dynamics", "ratio", "threshold", "attack", "release"],
            relatedArticles: ["compression-settings", "compressor-vs-limiter"]
        ),

        QAArticle(
            id: "compression-settings",
            title: "Setting Ratio and Threshold",
            category: .compression,
            difficulty: .intermediate,
            summary: "Practical guide to dialing in compressor settings for worship audio.",
            sections: [
                QASection(
                    heading: "Threshold First",
                    content: "Start with the ratio at 2:1. While the vocalist sings at their normal level, slowly lower the threshold until you see 3-6 dB of gain reduction on the loudest notes. The gain reduction meter shows you how much the compressor is working.",
                    tip: "If you see more than 10 dB of gain reduction, your threshold is too low or your ratio is too high."
                ),
                QASection(
                    heading: "Ratio Guidelines",
                    content: "2:1 — Gentle, transparent. Good for vocals and acoustic instruments. 3:1 — Moderate. Good for bass guitar and drums. 4:1 — Firm. Use for inconsistent singers or aggressive drums. Above 4:1 — Usually too aggressive for worship. Gets into limiting territory.",
                    tip: nil
                ),
                QASection(
                    heading: "Attack and Release",
                    content: "For vocals: 10-15ms attack, 100-150ms release. This lets the initial consonant through (for clarity) and releases smoothly between phrases. For kick drum: 5ms attack, 50ms release (fast to catch transients). For bass: 10ms attack, 80ms release.",
                    tip: "Fast attack + slow release = smooth and controlled. Slow attack + fast release = punchy and dynamic."
                )
            ],
            tags: ["compression", "ratio", "threshold", "attack", "release", "settings"],
            relatedArticles: ["what-does-compressor-do"]
        ),

        // ── Feedback Control ──
        QAArticle(
            id: "preventing-feedback",
            title: "How to Prevent Feedback",
            category: .feedback,
            difficulty: .beginner,
            summary: "Practical steps to prevent and eliminate microphone feedback during services.",
            sections: [
                QASection(
                    heading: "What Causes Feedback",
                    content: "Feedback occurs when the microphone picks up its own amplified sound from a speaker, creating a loop that gets louder and louder. The result is that familiar high-pitched squeal. It happens most often when: the mic is pointed at a speaker, the gain is too high, or the room is very reflective.",
                    tip: "The number one rule: keep microphones behind the speakers, never in front of them."
                ),
                QASection(
                    heading: "Prevention Steps",
                    content: "1. Position speakers in front of (not behind) the stage microphones. 2. Use cardioid mics — they reject sound from behind. 3. Keep gain as low as practical. 4. Use HPF on every channel to remove low-frequency rumble. 5. Keep monitors at reasonable levels. 6. Use in-ear monitors instead of wedges when possible.",
                    tip: nil
                ),
                QASection(
                    heading: "If Feedback Happens Live",
                    content: "Stay calm. Immediately pull down the fader of the offending channel. If you don't know which channel, pull down the master fader first, then bring channels back up one at a time. Once identified, slightly reduce the gain or apply a narrow EQ cut at the feedback frequency.",
                    tip: "Don't panic and yank everything down — a quick, calm fader pull is all you need."
                )
            ],
            tags: ["feedback", "squeal", "monitors", "microphone", "speakers", "positioning"],
            relatedArticles: ["ring-out-monitors"]
        ),

        QAArticle(
            id: "ring-out-monitors",
            title: "How to Ring Out Monitors",
            category: .feedback,
            difficulty: .advanced,
            summary: "Advanced technique for finding and notching feedback frequencies in stage monitors.",
            sections: [
                QASection(
                    heading: "What Is Ringing Out",
                    content: "Ringing out is the process of finding the frequencies where a monitor is most likely to feed back and applying narrow EQ cuts at those frequencies. This lets you push the monitor louder before feedback occurs. It's typically done during soundcheck with the band off stage.",
                    tip: "This is an advanced technique. Only attempt this if you're comfortable with your console's EQ and have time during soundcheck."
                ),
                QASection(
                    heading: "The Process",
                    content: "1. Open the mic channel and its monitor send. 2. Slowly raise the monitor send until you hear the first ring (a sustained tone). 3. Identify the frequency — use an RTA or your ear. 4. Apply a narrow notch cut (Q of 8-12) at that frequency, about -3 to -6 dB. 5. Continue raising the send until the next ring. 6. Repeat 3-5 times. 7. Back off the send by 3 dB for safety margin.",
                    tip: "Never ring out with the band on stage — their sound will mask the feedback frequencies."
                )
            ],
            tags: ["feedback", "ring out", "monitors", "notch", "advanced", "soundcheck"],
            relatedArticles: ["preventing-feedback"]
        ),

        // ── Vocal Mixing ──
        QAArticle(
            id: "vocal-eq-male-vs-female",
            title: "EQ for Male vs Female Vocals",
            category: .vocals,
            difficulty: .intermediate,
            summary: "How vocal EQ differs between male and female voices due to fundamental frequency ranges.",
            sections: [
                QASection(
                    heading: "Male Vocal Range",
                    content: "Male vocals typically sit between 85 Hz and 350 Hz (fundamental). The body and warmth is around 150-250 Hz. Presence lives at 2-4 kHz. Air is at 8-12 kHz. HPF at 80-100 Hz to remove rumble without thinning the voice. A gentle cut at 200-300 Hz can reduce boominess, especially with proximity effect.",
                    tip: "Male vocals often need a slight presence boost around 3 kHz to cut through the mix."
                ),
                QASection(
                    heading: "Female Vocal Range",
                    content: "Female vocals sit higher, typically 165-700 Hz (fundamental). Body is around 200-400 Hz. Presence is at 3-5 kHz. Air at 10-14 kHz. HPF at 100-150 Hz — you can go higher than male vocals. Watch for harshness around 3-5 kHz; female vocals are more prone to sibilance.",
                    tip: "Female vocals often benefit from a subtle air boost above 10 kHz for sparkle."
                )
            ],
            tags: ["vocals", "eq", "male", "female", "presence", "hpf", "sibilance"],
            relatedArticles: ["muddy-frequencies", "reduce-harshness"]
        ),

        // ── Instrument Mixing ──
        QAArticle(
            id: "drum-mixing-basics",
            title: "Drum Mixing Basics",
            category: .instruments,
            difficulty: .intermediate,
            summary: "Essential techniques for mixing a drum kit in a worship setting with common mic setups.",
            sections: [
                QASection(
                    heading: "Kick Drum",
                    content: "The kick provides the foundation. HPF at 30-40 Hz to remove sub-rumble. Cut mud at 300-400 Hz. Boost attack at 3-5 kHz for beater click. The fundamental punch lives at 60-80 Hz. Use moderate compression (3:1, fast attack) to even out dynamics.",
                    tip: "In a worship context, the kick should be felt more than heard. Keep it tight and controlled."
                ),
                QASection(
                    heading: "Snare Drum",
                    content: "HPF at 80-100 Hz. The body is at 150-250 Hz, the crack at 2-4 kHz, and the ring at 800-1000 Hz (cut if boxy). A small boost at 5 kHz adds snap. Compression at 3:1 helps even out ghost notes vs rimshots.",
                    tip: nil
                ),
                QASection(
                    heading: "Overheads and Cymbals",
                    content: "Overheads capture the overall kit sound. HPF at 200-300 Hz (let the close mics handle the low end). They provide the cymbal detail and stereo image. Keep them relatively flat — the overheads should sound like what you hear standing next to the kit.",
                    tip: "If cymbals are too harsh, a gentle cut at 3-5 kHz or a low-pass filter at 14 kHz can help."
                )
            ],
            tags: ["drums", "kick", "snare", "overheads", "cymbals", "eq", "compression"],
            relatedArticles: ["what-does-compressor-do"]
        ),

        // ── Monitor Mixing ──
        QAArticle(
            id: "setting-up-iems",
            title: "Setting Up In-Ear Monitors",
            category: .monitors,
            difficulty: .intermediate,
            summary: "Practical guide to setting up and mixing in-ear monitors for worship teams.",
            sections: [
                QASection(
                    heading: "Why IEMs?",
                    content: "In-ear monitors (IEMs) replace floor wedge monitors. Benefits: reduced stage volume, better hearing protection, more control per musician, and less feedback risk. The trade-off is they can feel isolated — musicians miss the 'feel' of the room.",
                    tip: "Always include a small amount of room/ambient mic in the IEM mix so musicians feel connected to the room."
                ),
                QASection(
                    heading: "Basic IEM Mix",
                    content: "Every musician needs to hear: 1) Themselves (loudest). 2) The leader/lead vocal. 3) A musical reference (keys or acoustic guitar). 4) Click track (if using tracks). 5) A touch of room/ambient mic. Start with these five elements and add more only if requested.",
                    tip: "Less is more in IEM mixes. A cluttered IEM mix causes musicians to push their own level higher, starting a volume war."
                ),
                QASection(
                    heading: "Volume Safety",
                    content: "IEMs sit directly in the ear canal, so volume control is critical. A good target is 80-85 dB SPL in the ear. Most wireless IEM systems have a limiter — make sure it's enabled. Encourage musicians to start quiet and only bring up what they need.",
                    tip: "Custom-molded IEMs with better isolation let musicians hear clearly at lower volumes."
                )
            ],
            tags: ["iem", "in-ear", "monitors", "wedges", "stage volume", "mix"],
            relatedArticles: ["preventing-feedback"]
        ),

        // ── Room Acoustics ──
        QAArticle(
            id: "understanding-rt60",
            title: "Understanding RT60",
            category: .roomAcoustics,
            difficulty: .intermediate,
            summary: "What RT60 means, how it affects your mix, and what your room's number tells you.",
            sections: [
                QASection(
                    heading: "What Is RT60?",
                    content: "RT60 (Reverberation Time 60) is the time it takes for a sound to decay by 60 dB after the source stops. A clap in an empty room that rings for 2 seconds has an RT60 of roughly 2 seconds. Shorter RT60 means a drier, more controlled room. Longer means more reverberant.",
                    tip: nil
                ),
                QASection(
                    heading: "What's Ideal for Worship?",
                    content: "For worship spaces that balance speech and music, an RT60 of 0.8-1.2 seconds is generally ideal. Below 0.8s, music can sound dry and lifeless. Above 1.5s, speech clarity suffers significantly. Many traditional churches sit at 1.5-3.0 seconds due to hard surfaces.",
                    tip: "You can measure your room's RT60 using the Room Acoustics tool in this app."
                ),
                QASection(
                    heading: "How It Affects Your Mix",
                    content: "In reverberant rooms: use less effects reverb (the room provides plenty), cut low-mids more aggressively (they build up), use tighter compression to control sustain, and keep the mix drier overall. In dry rooms: you have more freedom with effects and can let instruments ring out naturally.",
                    tip: nil
                )
            ],
            tags: ["rt60", "reverb", "room", "acoustics", "decay", "treatment"],
            relatedArticles: []
        )
    ]
}
