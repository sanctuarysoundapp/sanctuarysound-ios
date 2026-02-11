// ============================================================================
// QABuiltInContent.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Store Layer
// Purpose: Built-in Q&A articles for the Sound Engineer knowledge base.
//          Contains 46 articles across 11 categories covering all aspects
//          of live sound engineering for house of worship environments.
// ============================================================================

import Foundation


// MARK: - ─── Built-In Q&A Content ─────────────────────────────────────────────

struct QABuiltInContent {

    static let allArticles: [QAArticle] = gainStagingArticles
        + eqArticles
        + compressionArticles
        + feedbackArticles
        + vocalArticles
        + instrumentArticles
        + monitorArticles
        + roomAcousticsArticles
        + mixerSetupArticles
        + troubleshootingArticles
        + advancedTechniqueArticles


    // MARK: - ─── Gain Staging (5) ─────────────────────────────────────────────

    private static let gainStagingArticles: [QAArticle] = [
        QAArticle(
            id: "gain-staging-basics",
            title: "What Is Gain Staging?",
            category: .gainStaging,
            difficulty: .beginner,
            summary: "Learn why proper gain staging is the foundation of a good mix and how to set your preamp levels correctly.",
            sections: [
                QASection(heading: "Why It Matters", content: "Gain staging is the process of setting the right signal level at each point in the audio chain. Too low, and you get hiss and noise. Too high, and you get distortion and clipping. The goal is to hit the 'sweet spot' where the signal is clean and strong.", tip: "On digital consoles, aim for your signal to sit around -18 dBFS on the meter. This gives you 18 dB of headroom before clipping."),
                QASection(heading: "Setting the Preamp", content: "Have the vocalist sing at their loudest expected level during soundcheck. Slowly bring up the gain until the meter reads around -18 dBFS on the loudest peaks. The meter should bounce comfortably without hitting the red. Once gain is set, use the fader for mix balance — don't touch the gain knob during service.", tip: "A common mistake is setting gain too hot during soundcheck when people are quiet, then getting surprised when the band plays full volume."),
                QASection(heading: "The Gain-Fader Relationship", content: "Think of gain as 'how loud is the raw signal' and fader as 'how loud do I want this in the mix.' Gain is set once during soundcheck. Faders are used throughout the service to balance the mix. If you find yourself pushing a fader above unity (0 dB), your gain might be too low.", tip: nil)
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
                QASection(heading: "Low Gain, High Fader", content: "The most common cause of hiss is setting the preamp gain too low and compensating with a high fader level. When you amplify a quiet signal, you also amplify the noise floor. The fix: bring the gain up until the signal reads around -18 dBFS, then bring the fader back down.", tip: "If the fader is above +5 dB and you hear hiss, your gain is almost certainly too low."),
                QASection(heading: "Cable and Connection Issues", content: "Bad XLR cables, loose connections, and unbalanced runs over long distances can introduce noise. Check your cables by swapping them one at a time. Use balanced cables for all runs over 15 feet.", tip: nil),
                QASection(heading: "Phantom Power Issues", content: "Condenser mics need 48V phantom power. If a condenser mic sounds noisy or weak, check that phantom power is enabled on that channel. Conversely, some ribbon mics can be damaged by phantom power — always check your mic type.", tip: nil)
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
                QASection(heading: "What Is a PAD?", content: "The PAD button attenuates (reduces) the incoming signal by a fixed amount, typically 20 dB. It's used when a source is so loud that even with the gain knob at minimum, the signal is still clipping.", tip: "Common scenario: a keyboard sending line-level (+4 dBu) into a mic-level input. The PAD brings it down to a manageable level."),
                QASection(heading: "When to Use It", content: "Use the PAD when: the gain knob is at its lowest setting and the signal is still too hot, you're receiving a line-level signal into a mic input, or a drummer is hitting incredibly hard on a close-miked drum. You generally don't need PAD for normal vocal mics.", tip: nil)
            ],
            tags: ["pad", "gain", "preamp", "line level", "hot signal"],
            relatedArticles: ["gain-staging-basics"]
        ),

        QAArticle(
            id: "gain-staging-for-di",
            title: "Gain Staging for DI Sources",
            category: .gainStaging,
            difficulty: .intermediate,
            summary: "How to set proper levels for keyboards, bass guitar, and tracks coming in via DI or line inputs.",
            sections: [
                QASection(heading: "DI vs Mic Signals", content: "DI (Direct Input) sources like keyboards, bass guitars, and tracks are already at a much higher level than microphones. A mic might output -50 dBu while a keyboard outputs +4 dBu. This means DI channels need significantly less preamp gain — often near minimum.", tip: "If a DI source is clipping with gain at minimum, engage the PAD or use a dedicated line-level input."),
                QASection(heading: "Setting DI Levels", content: "Have the keyboard player hit their loudest chord or the bass player dig in hard. Set the gain so peaks read around -18 dBFS. For stereo keyboards, match the gain on both channels. For tracks playback, play the loudest section and set gain accordingly.", tip: "Stereo DI sources should have identical gain on both channels. A mismatch will skew the stereo image.")
            ],
            tags: ["di", "gain", "keyboard", "bass", "tracks", "line level"],
            relatedArticles: ["gain-staging-basics", "what-does-pad-do", "keyboard-mixing"]
        ),

        QAArticle(
            id: "console-metering-scales",
            title: "Understanding Console Metering",
            category: .gainStaging,
            difficulty: .intermediate,
            summary: "How different consoles display levels, and why knowing your metering scale matters for gain staging.",
            sections: [
                QASection(heading: "Peak vs RMS Metering", content: "Peak meters show the absolute highest level of the signal — great for catching clipping. RMS meters show the average level, which better represents perceived loudness. Most digital consoles default to peak metering, but some offer VU-style RMS display.", tip: "When gain staging, always use peak metering to protect against clipping. Switch to RMS when judging overall mix balance."),
                QASection(heading: "Pre-Fade vs Post-Fade", content: "Pre-fade meters show the signal level before the fader. Post-fade meters show the level after the fader. Use pre-fade metering during soundcheck to set gain without fader position affecting the reading. Post-fade is useful for checking what is actually reaching the mix bus.", tip: "On A&H consoles, channel meters are typically pre-fade by default. On X32/M32, you can toggle metering points in setup.")
            ],
            tags: ["metering", "peak", "rms", "vu", "pre-fade", "post-fade", "levels"],
            relatedArticles: ["gain-staging-basics", "gain-staging-for-di"],
            consoleTags: ["avantis", "sq", "dlive", "x32", "m32", "tf", "cl", "ql"]
        ),
    ]


    // MARK: - ─── EQ Basics (5) ────────────────────────────────────────────────

    private static let eqArticles: [QAArticle] = [
        QAArticle(
            id: "muddy-frequencies",
            title: "What Frequencies Are 'Muddy'?",
            category: .eq,
            difficulty: .beginner,
            summary: "Learn to identify and tame the 200-500 Hz range that causes muddy, unclear mixes.",
            sections: [
                QASection(heading: "The Mud Zone", content: "The frequency range from roughly 200 Hz to 500 Hz is where 'mud' lives. When multiple instruments pile up energy in this range, the mix sounds thick, boomy, and unclear. Almost every source has content here — vocals, guitars, keys, drums — so it builds up fast.", tip: "A 3 dB cut at 300 Hz on several channels can dramatically clean up your overall mix."),
                QASection(heading: "How to Fix It", content: "Use a parametric EQ to make gentle cuts (2-4 dB) in the 200-500 Hz range on channels that don't need low-mid body. Acoustic guitar, keyboards, and backing vocals are good candidates for low-mid cuts. Leave the low-mid content on bass guitar, kick drum, and the lead vocal — they need it for warmth.", tip: "Cut mud on everything except the instruments that own that frequency range."),
                QASection(heading: "Subtractive EQ Philosophy", content: "Instead of boosting frequencies you want more of, cut the frequencies you want less of. Cutting is almost always better than boosting — it sounds more natural, uses less headroom, and is less likely to cause feedback.", tip: nil)
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
                QASection(heading: "The Harshness Zone", content: "Frequencies between 2 kHz and 5 kHz are where harshness and 'ear fatigue' live. Our ears are most sensitive in this range (it's where speech consonants sit), so even small peaks here sound very aggressive. Cymbals, distorted guitars, and sibilant vocals are common offenders.", tip: "Sweep a narrow EQ boost through 2-5 kHz to find the exact offending frequency, then cut it by 2-4 dB."),
                QASection(heading: "De-Essing Vocals", content: "If vocals sound sibilant (harsh 'S' and 'T' sounds), you can use a narrow EQ cut around 5-8 kHz or, if your console has one, a de-esser. A 2-3 dB cut with a medium-narrow Q at the sibilant frequency usually does the trick.", tip: nil)
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
                QASection(heading: "Subtractive EQ (Cutting)", content: "Removing unwanted frequencies is the foundation of good EQ practice. Cuts sound natural, reduce the chance of feedback, preserve headroom, and can be more aggressive without sounding bad. Most of your EQ moves should be cuts.", tip: "A good starting approach: HPF to remove rumble, cut the mud zone (200-400 Hz), and cut any harsh resonances."),
                QASection(heading: "When to Boost", content: "Boosting is appropriate for adding 'air' (subtle +2 dB shelf above 10 kHz), adding presence to a vocal (+1-2 dB around 3-4 kHz), or brightening a dull source. Keep boosts gentle — under +3 dB is ideal. Large boosts often indicate a problem that should be fixed at the source.", tip: nil)
            ],
            tags: ["eq", "subtractive", "additive", "boost", "cut", "technique"],
            relatedArticles: ["muddy-frequencies", "reduce-harshness"]
        ),

        QAArticle(
            id: "high-pass-filter-guide",
            title: "The High-Pass Filter: Your Best Friend",
            category: .eq,
            difficulty: .beginner,
            summary: "Why every channel needs an HPF and recommended cutoff frequencies for common sources.",
            sections: [
                QASection(heading: "What Is an HPF?", content: "A High-Pass Filter (HPF) removes low frequencies below a set cutoff point. It 'passes' the highs and cuts the lows. Every channel on your console has one, and you should use it on almost everything. It removes rumble, handling noise, stage vibration, and HVAC noise.", tip: "Enable the HPF on every channel as your first move during soundcheck. Only leave it off on kick drum and bass guitar sub channels."),
                QASection(heading: "Recommended Frequencies", content: "Male vocals: 80-100 Hz. Female vocals: 100-150 Hz. Acoustic guitar: 80-120 Hz. Electric guitar: 100-150 Hz. Keyboards: 60-100 Hz. Snare: 80-100 Hz. Overheads: 200-300 Hz. Toms: 60-80 Hz. The goal is to remove everything below the source's useful range.", tip: "If you can raise the HPF without thinning the sound, it is not high enough yet. Push it up until you just start to hear the low end thin out, then back off slightly.")
            ],
            tags: ["hpf", "high-pass", "filter", "rumble", "eq", "low-cut"],
            relatedArticles: ["muddy-frequencies", "gain-staging-basics"]
        ),

        QAArticle(
            id: "console-eq-differences",
            title: "EQ Differences Across Consoles",
            category: .eq,
            difficulty: .intermediate,
            summary: "How PEQ band counts and types differ between popular digital consoles used in churches.",
            sections: [
                QASection(heading: "Band Count and Flexibility", content: "Allen & Heath Avantis/dLive offer 4-band fully parametric EQ plus HPF/LPF on every channel. The X32/M32 provides 6-band parametric EQ. Yamaha TF uses a simplified 4-band EQ with 1-knob modes. More bands give you finer control for surgical cuts.", tip: "Even with only 4 PEQ bands, you can handle most worship scenarios. Prioritize: HPF, one mud cut, one harshness cut, and one presence adjustment."),
                QASection(heading: "DEEP Processing (A&H)", content: "Allen & Heath's DEEP processing (dPack on Avantis) adds vintage-modeled EQ and dynamics to every channel. These behave differently from standard PEQ — they add harmonic character. Use DEEP EQ for musical tone shaping and standard PEQ for corrective cuts.", tip: "DEEP compressors like the Opto model are excellent on vocals — they add smooth, musical leveling that is hard to achieve with standard compression.")
            ],
            tags: ["eq", "peq", "deep", "console", "bands", "parametric"],
            relatedArticles: ["subtractive-vs-additive", "deep-processing-guide"],
            consoleTags: ["avantis", "sq", "dlive", "x32", "m32"]
        ),
    ]


    // MARK: - ─── Compression (4) ──────────────────────────────────────────────

    private static let compressionArticles: [QAArticle] = [
        QAArticle(
            id: "what-does-compressor-do",
            title: "What Does a Compressor Do?",
            category: .compression,
            difficulty: .beginner,
            summary: "Understanding dynamic range compression — making quiet parts louder and loud parts quieter.",
            sections: [
                QASection(heading: "The Basic Idea", content: "A compressor automatically reduces the volume when the signal gets too loud. This evens out the dynamic range — the difference between the quietest and loudest moments. For vocals, this means the whispered verse and the belted chorus sit at more consistent levels in the mix.", tip: "Think of a compressor as an automatic hand on the fader, turning it down when things get loud."),
                QASection(heading: "Key Controls", content: "Threshold: the level at which compression kicks in. Ratio: how much the signal is reduced (2:1 means for every 2 dB over threshold, only 1 dB comes through). Attack: how quickly compression engages. Release: how quickly it lets go. Start with gentle settings: -20 dB threshold, 2:1 ratio, 10ms attack, 100ms release.", tip: nil),
                QASection(heading: "When to Use It", content: "Compression is most useful on vocals (evening out dynamics), bass guitar (consistent low end), and drum overheads (controlling cymbal peaks). For church sound, keep ratios between 2:1 and 4:1 — aggressive compression (above 4:1) can cause pumping artifacts that sound unnatural.", tip: "If you can hear the compressor working, it's probably too aggressive. Good compression should be invisible.")
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
                QASection(heading: "Threshold First", content: "Start with the ratio at 2:1. While the vocalist sings at their normal level, slowly lower the threshold until you see 3-6 dB of gain reduction on the loudest notes. The gain reduction meter shows you how much the compressor is working.", tip: "If you see more than 10 dB of gain reduction, your threshold is too low or your ratio is too high."),
                QASection(heading: "Ratio Guidelines", content: "2:1 — Gentle, transparent. Good for vocals and acoustic instruments. 3:1 — Moderate. Good for bass guitar and drums. 4:1 — Firm. Use for inconsistent singers or aggressive drums. Above 4:1 — Usually too aggressive for worship. Gets into limiting territory.", tip: nil),
                QASection(heading: "Attack and Release", content: "For vocals: 10-15ms attack, 100-150ms release. This lets the initial consonant through (for clarity) and releases smoothly between phrases. For kick drum: 5ms attack, 50ms release (fast to catch transients). For bass: 10ms attack, 80ms release.", tip: "Fast attack + slow release = smooth and controlled. Slow attack + fast release = punchy and dynamic.")
            ],
            tags: ["compression", "ratio", "threshold", "attack", "release", "settings"],
            relatedArticles: ["what-does-compressor-do"]
        ),

        QAArticle(
            id: "compressor-vs-limiter",
            title: "Compressor vs Limiter",
            category: .compression,
            difficulty: .intermediate,
            summary: "Understanding the difference between compression and limiting, and when to use each in worship audio.",
            sections: [
                QASection(heading: "The Difference", content: "A limiter is essentially a compressor with a very high ratio (10:1 or higher). While a compressor gently reduces levels above threshold, a limiter acts as a hard ceiling — nothing gets through above the set level. Think of compression as shaping dynamics and limiting as protecting against peaks.", tip: "A limiter on your main bus is a safety net — it prevents accidental speaker-damaging peaks from reaching the PA."),
                QASection(heading: "When to Use Each", content: "Use compression on individual channels for dynamic control (vocals, bass, drums). Use a limiter on the main output bus as a safety ceiling. In worship, a bus limiter set at -3 dBFS protects your speakers while allowing musical dynamics. Never use a limiter on individual vocal channels — it sounds harsh and unnatural.", tip: nil)
            ],
            tags: ["compressor", "limiter", "dynamics", "ratio", "bus", "protection"],
            relatedArticles: ["what-does-compressor-do", "compression-settings"]
        ),

        QAArticle(
            id: "deep-processing-guide",
            title: "A&H DEEP Processing Guide",
            category: .compression,
            difficulty: .advanced,
            summary: "How to use Allen & Heath's DEEP processing (dPack) for musical compression and EQ modeling.",
            sections: [
                QASection(heading: "What Is DEEP?", content: "DEEP (Dynamic EQ Effects Processing) is Allen & Heath's built-in processing that models classic analog hardware. On Avantis with dPack, every channel gets access to vintage compressor models (Opto, FET, VCA) and EQ models. These add harmonic character that standard digital processing does not.", tip: "The DEEP Opto compressor is a worship vocal favorite — it provides smooth, transparent leveling without artifacts."),
                QASection(heading: "Practical Application", content: "Use DEEP compressors for musical tone shaping and the standard compressor for corrective dynamics. For lead vocals, try the Opto model with a moderate threshold. For drums, the FET model adds punch. Keep the standard channel compressor available for surgical control on top of the DEEP processing.", tip: "DEEP processing adds latency. For IEM mixes where latency matters, test whether the added latency is noticeable to your musicians.")
            ],
            tags: ["deep", "dpack", "opto", "modeling", "allen heath", "processing"],
            relatedArticles: ["compression-settings", "console-eq-differences"],
            consoleTags: ["avantis", "dlive"]
        ),
    ]


    // MARK: - ─── Feedback Control (3) ─────────────────────────────────────────

    private static let feedbackArticles: [QAArticle] = [
        QAArticle(
            id: "preventing-feedback",
            title: "How to Prevent Feedback",
            category: .feedback,
            difficulty: .beginner,
            summary: "Practical steps to prevent and eliminate microphone feedback during services.",
            sections: [
                QASection(heading: "What Causes Feedback", content: "Feedback occurs when the microphone picks up its own amplified sound from a speaker, creating a loop that gets louder and louder. The result is that familiar high-pitched squeal. It happens most often when: the mic is pointed at a speaker, the gain is too high, or the room is very reflective.", tip: "The number one rule: keep microphones behind the speakers, never in front of them."),
                QASection(heading: "Prevention Steps", content: "1. Position speakers in front of (not behind) the stage microphones. 2. Use cardioid mics — they reject sound from behind. 3. Keep gain as low as practical. 4. Use HPF on every channel to remove low-frequency rumble. 5. Keep monitors at reasonable levels. 6. Use in-ear monitors instead of wedges when possible.", tip: nil),
                QASection(heading: "If Feedback Happens Live", content: "Stay calm. Immediately pull down the fader of the offending channel. If you don't know which channel, pull down the master fader first, then bring channels back up one at a time. Once identified, slightly reduce the gain or apply a narrow EQ cut at the feedback frequency.", tip: "Don't panic and yank everything down — a quick, calm fader pull is all you need.")
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
                QASection(heading: "What Is Ringing Out", content: "Ringing out is the process of finding the frequencies where a monitor is most likely to feed back and applying narrow EQ cuts at those frequencies. This lets you push the monitor louder before feedback occurs. It's typically done during soundcheck with the band off stage.", tip: "This is an advanced technique. Only attempt this if you're comfortable with your console's EQ and have time during soundcheck."),
                QASection(heading: "The Process", content: "1. Open the mic channel and its monitor send. 2. Slowly raise the monitor send until you hear the first ring (a sustained tone). 3. Identify the frequency — use an RTA or your ear. 4. Apply a narrow notch cut (Q of 8-12) at that frequency, about -3 to -6 dB. 5. Continue raising the send until the next ring. 6. Repeat 3-5 times. 7. Back off the send by 3 dB for safety margin.", tip: "Never ring out with the band on stage — their sound will mask the feedback frequencies.")
            ],
            tags: ["feedback", "ring out", "monitors", "notch", "advanced", "soundcheck"],
            relatedArticles: ["preventing-feedback"]
        ),

        QAArticle(
            id: "feedback-during-service",
            title: "Feedback During a Live Service",
            category: .feedback,
            difficulty: .beginner,
            summary: "Quick action plan for handling feedback in the moment during a live worship service.",
            sections: [
                QASection(heading: "Immediate Response", content: "When feedback strikes mid-service, pull the suspect fader down smoothly — do not slam it to zero. If you are unsure which channel is causing it, reduce the overall mix level first. The congregation will barely notice a brief dip, but a panicked overcorrection is far more disruptive.", tip: "Keep one hand near the master fader during transitions when musicians move microphones or switch instruments."),
                QASection(heading: "Finding the Culprit", content: "Common mid-service feedback causes: a vocalist stepping in front of a wedge monitor, a handheld mic pointed at the PA, or a musician turning up their own monitor send. After pulling the level down, glance at the stage to identify what changed. Bring the channel back up slowly once the source issue is resolved.", tip: "Mark your fader positions with tape during soundcheck so you can quickly restore levels after pulling them down.")
            ],
            tags: ["feedback", "live", "service", "emergency", "troubleshooting"],
            relatedArticles: ["preventing-feedback", "ring-out-monitors"]
        ),
    ]


    // MARK: - ─── Vocal Mixing (4) ─────────────────────────────────────────────

    private static let vocalArticles: [QAArticle] = [
        QAArticle(
            id: "vocal-eq-male-vs-female",
            title: "EQ for Male vs Female Vocals",
            category: .vocals,
            difficulty: .intermediate,
            summary: "How vocal EQ differs between male and female voices due to fundamental frequency ranges.",
            sections: [
                QASection(heading: "Male Vocal Range", content: "Male vocals typically sit between 85 Hz and 350 Hz (fundamental). The body and warmth is around 150-250 Hz. Presence lives at 2-4 kHz. Air is at 8-12 kHz. HPF at 80-100 Hz to remove rumble without thinning the voice. A gentle cut at 200-300 Hz can reduce boominess, especially with proximity effect.", tip: "Male vocals often need a slight presence boost around 3 kHz to cut through the mix."),
                QASection(heading: "Female Vocal Range", content: "Female vocals sit higher, typically 165-700 Hz (fundamental). Body is around 200-400 Hz. Presence is at 3-5 kHz. Air at 10-14 kHz. HPF at 100-150 Hz — you can go higher than male vocals. Watch for harshness around 3-5 kHz; female vocals are more prone to sibilance.", tip: "Female vocals often benefit from a subtle air boost above 10 kHz for sparkle.")
            ],
            tags: ["vocals", "eq", "male", "female", "presence", "hpf", "sibilance"],
            relatedArticles: ["muddy-frequencies", "reduce-harshness"]
        ),

        QAArticle(
            id: "lead-vocal-priority",
            title: "The Lead Vocal Is King",
            category: .vocals,
            difficulty: .beginner,
            summary: "Why the lead vocal should always be the loudest and clearest element, and how to build around it.",
            sections: [
                QASection(heading: "Building the Mix", content: "Start every mix with the lead vocal. Bring it up first, set its gain, EQ, and compression, then build everything else underneath it. The congregation follows the lead vocalist — if they cannot hear the words clearly, the worship experience suffers.", tip: "A good test: mute the band and listen to the lead vocal alone. It should sound full, clear, and present without any effects."),
                QASection(heading: "Keeping It on Top", content: "If the lead vocal gets buried during loud passages, resist the urge to just push the vocal fader higher. Instead, pull the competing instruments down slightly. Common offenders that mask vocals are electric guitars in the 2-4 kHz range and cymbals. Small cuts on those channels create space for the vocal.", tip: "If you have to choose between the band sounding perfect and the vocal being clear, always choose vocal clarity.")
            ],
            tags: ["vocals", "lead", "mix", "priority", "clarity", "worship"],
            relatedArticles: ["vocal-eq-male-vs-female", "backing-vocal-blend"]
        ),

        QAArticle(
            id: "backing-vocal-blend",
            title: "Blending Backing Vocals",
            category: .vocals,
            difficulty: .intermediate,
            summary: "Techniques for making multiple backing vocalists sit together as a cohesive group behind the lead.",
            sections: [
                QASection(heading: "Group Cohesion", content: "Backing vocals should sound like one voice, not four individuals. Apply similar EQ and compression across all backing vocal channels. A gentle HPF at 120-150 Hz removes proximity rumble. Cut the 200-400 Hz range a bit more aggressively than on the lead vocal — backing vocals do not need as much warmth.", tip: "Route all backing vocals to a subgroup or VCA so you can control the overall backing level with one fader."),
                QASection(heading: "Sitting Behind the Lead", content: "Keep backing vocals 3-6 dB below the lead vocal in the mix. Roll off some high-end air above 12 kHz on the backings so the lead retains its sparkle. If one backing vocalist is naturally louder, apply a bit more compression on their channel rather than just pulling the fader down.", tip: "Pan backing vocals slightly left and right to create width while keeping the lead centered.")
            ],
            tags: ["vocals", "backing", "blend", "subgroup", "vca", "mix"],
            relatedArticles: ["lead-vocal-priority", "vocal-eq-male-vs-female"]
        ),

        QAArticle(
            id: "vocal-proximity-effect",
            title: "Managing Proximity Effect",
            category: .vocals,
            difficulty: .intermediate,
            summary: "What proximity effect is and how to handle vocalists who cup or eat the microphone.",
            sections: [
                QASection(heading: "What Is Proximity Effect?", content: "Proximity effect is a bass buildup that occurs when a directional (cardioid) microphone is used very close to the sound source. The closer the vocalist gets, the more low-frequency energy the mic captures. This makes the voice sound boomy and muddy.", tip: "A vocalist who cups the mic grille makes proximity effect even worse by turning the cardioid pattern into near-omnidirectional, reducing feedback rejection too."),
                QASection(heading: "How to Manage It", content: "The best fix is mic technique — encourage vocalists to keep the mic 1-2 inches from their mouth. If that is not practical, use a steeper HPF (120-150 Hz instead of 80 Hz) and a gentle cut at 200-300 Hz to counteract the bass buildup. Dynamic EQ can also help by cutting low frequencies only when they exceed a threshold.", tip: "During rehearsal, gently coach vocalists on mic distance. A consistent distance produces a consistent sound that is much easier to mix.")
            ],
            tags: ["proximity", "bass", "microphone", "technique", "hpf", "vocals"],
            relatedArticles: ["vocal-eq-male-vs-female", "high-pass-filter-guide"]
        ),
    ]


    // MARK: - ─── Instrument Mixing (4) ────────────────────────────────────────

    private static let instrumentArticles: [QAArticle] = [
        QAArticle(
            id: "drum-mixing-basics",
            title: "Drum Mixing Basics",
            category: .instruments,
            difficulty: .intermediate,
            summary: "Essential techniques for mixing a drum kit in a worship setting with common mic setups.",
            sections: [
                QASection(heading: "Kick Drum", content: "The kick provides the foundation. HPF at 30-40 Hz to remove sub-rumble. Cut mud at 300-400 Hz. Boost attack at 3-5 kHz for beater click. The fundamental punch lives at 60-80 Hz. Use moderate compression (3:1, fast attack) to even out dynamics.", tip: "In a worship context, the kick should be felt more than heard. Keep it tight and controlled."),
                QASection(heading: "Snare Drum", content: "HPF at 80-100 Hz. The body is at 150-250 Hz, the crack at 2-4 kHz, and the ring at 800-1000 Hz (cut if boxy). A small boost at 5 kHz adds snap. Compression at 3:1 helps even out ghost notes vs rimshots.", tip: nil),
                QASection(heading: "Overheads and Cymbals", content: "Overheads capture the overall kit sound. HPF at 200-300 Hz (let the close mics handle the low end). They provide the cymbal detail and stereo image. Keep them relatively flat — the overheads should sound like what you hear standing next to the kit.", tip: "If cymbals are too harsh, a gentle cut at 3-5 kHz or a low-pass filter at 14 kHz can help.")
            ],
            tags: ["drums", "kick", "snare", "overheads", "cymbals", "eq", "compression"],
            relatedArticles: ["what-does-compressor-do"]
        ),

        QAArticle(
            id: "bass-guitar-mixing",
            title: "Bass Guitar Mixing",
            category: .instruments,
            difficulty: .intermediate,
            summary: "Getting a tight, consistent bass guitar sound via DI with proper EQ and compression.",
            sections: [
                QASection(heading: "DI Bass Fundamentals", content: "Most church bass players go direct via a DI box or modeler. HPF at 30-40 Hz to remove sub-bass rumble. The fundamental sits at 60-100 Hz, body at 100-250 Hz, and finger/string definition at 700 Hz-2 kHz. A gentle cut at 200-300 Hz prevents overlap with the kick drum.", tip: "If the bass and kick are fighting, decide who owns 60-80 Hz and who owns 100-120 Hz, then carve accordingly."),
                QASection(heading: "Compression for Bass", content: "Bass guitar benefits greatly from compression. Use a 3:1 or 4:1 ratio with a medium attack (10ms) to keep the note attack while evening out the sustain. Aim for 4-6 dB of gain reduction on the loudest notes. This keeps the low end solid and predictable throughout the service.", tip: "A consistent bass level is more important than a dynamic one in worship — the bass is the harmonic foundation for everything else.")
            ],
            tags: ["bass", "di", "eq", "compression", "low end", "kick"],
            relatedArticles: ["drum-mixing-basics", "gain-staging-for-di"]
        ),

        QAArticle(
            id: "electric-guitar-mixing",
            title: "Electric Guitar Mixing",
            category: .instruments,
            difficulty: .intermediate,
            summary: "Mixing electric guitars from modelers or amp mics, managing mid-range presence, and fitting in the mix.",
            sections: [
                QASection(heading: "Modeler vs Amp-Mic", content: "Most churches use modelers (Helix, Kemper, AxeFX) going direct. The tone is shaped at the source, so your job is mainly level and frequency management. HPF at 100-150 Hz. If using an amp mic, the mic choice and placement matter more — start with a dynamic mic on the cone edge for a balanced tone.", tip: "Ask the guitarist to dial back their modeler's output level if the signal is too hot for the console input."),
                QASection(heading: "Fitting Guitars in the Mix", content: "Electric guitars live in the mid-range (200 Hz-5 kHz) — the same space as vocals. A gentle cut at 2-3 kHz on the guitar creates a pocket for the lead vocal to sit in. Pan two electric guitars left and right for width. Keep them below the vocal in level during singing sections.", tip: "During instrumental sections, you can push the guitars up. During vocal-heavy worship moments, pull them back to support rather than compete.")
            ],
            tags: ["guitar", "electric", "modeler", "amp", "mid-range", "pan"],
            relatedArticles: ["bass-guitar-mixing", "lead-vocal-priority"]
        ),

        QAArticle(
            id: "keyboard-mixing",
            title: "Mixing Keyboards and Pads",
            category: .instruments,
            difficulty: .beginner,
            summary: "Managing stereo keyboard inputs, pads, and frequency separation from other instruments.",
            sections: [
                QASection(heading: "Stereo Channel Management", content: "Keyboards typically come in as a stereo pair (left and right DI). Keep both channels gain-matched and panned hard left and right. HPF at 60-80 Hz unless the keyboard is covering the bass role. If the keys player uses pads, those are often better on a separate stereo pair so you can control them independently.", tip: "Label your keyboard channels clearly: 'Keys L' and 'Keys R' or 'Pads L' and 'Pads R' to avoid confusion during service."),
                QASection(heading: "Frequency Management", content: "Keyboards can cover a huge frequency range and easily clash with guitars, vocals, and bass. A gentle cut at 200-400 Hz reduces mud. If the keys part is a pad, roll off above 8 kHz to keep it as a warm bed underneath. For piano tones, leave more high-end for clarity.", tip: "Communication with the keys player helps — ask them to choose patches that complement rather than duplicate the guitar tones.")
            ],
            tags: ["keyboard", "piano", "pads", "stereo", "di", "frequency"],
            relatedArticles: ["gain-staging-for-di", "muddy-frequencies"]
        ),
    ]


    // MARK: - ─── Monitor Mixing (3) ───────────────────────────────────────────

    private static let monitorArticles: [QAArticle] = [
        QAArticle(
            id: "setting-up-iems",
            title: "Setting Up In-Ear Monitors",
            category: .monitors,
            difficulty: .intermediate,
            summary: "Practical guide to setting up and mixing in-ear monitors for worship teams.",
            sections: [
                QASection(heading: "Why IEMs?", content: "In-ear monitors (IEMs) replace floor wedge monitors. Benefits: reduced stage volume, better hearing protection, more control per musician, and less feedback risk. The trade-off is they can feel isolated — musicians miss the 'feel' of the room.", tip: "Always include a small amount of room/ambient mic in the IEM mix so musicians feel connected to the room."),
                QASection(heading: "Basic IEM Mix", content: "Every musician needs to hear: 1) Themselves (loudest). 2) The leader/lead vocal. 3) A musical reference (keys or acoustic guitar). 4) Click track (if using tracks). 5) A touch of room/ambient mic. Start with these five elements and add more only if requested.", tip: "Less is more in IEM mixes. A cluttered IEM mix causes musicians to push their own level higher, starting a volume war."),
                QASection(heading: "Volume Safety", content: "IEMs sit directly in the ear canal, so volume control is critical. A good target is 80-85 dB SPL in the ear. Most wireless IEM systems have a limiter — make sure it's enabled. Encourage musicians to start quiet and only bring up what they need.", tip: "Custom-molded IEMs with better isolation let musicians hear clearly at lower volumes.")
            ],
            tags: ["iem", "in-ear", "monitors", "wedges", "stage volume", "mix"],
            relatedArticles: ["preventing-feedback"]
        ),

        QAArticle(
            id: "wedge-vs-iem",
            title: "Wedges vs In-Ear Monitors",
            category: .monitors,
            difficulty: .beginner,
            summary: "Comparing floor wedge monitors and in-ear monitors for worship teams: pros, cons, and when to use each.",
            sections: [
                QASection(heading: "Floor Wedges", content: "Wedges are speaker cabinets placed on stage pointing at musicians. They are simple to set up and feel natural — musicians hear sound the way they are used to. The downsides: they add volume to the stage, increase feedback risk, and give less individual control.", tip: "If you use wedges, keep them as quiet as possible. Stage volume from wedges bleeds into every mic on stage."),
                QASection(heading: "In-Ear Monitors", content: "IEMs provide isolated, personal monitor mixes directly into each musician's ears. They eliminate stage volume issues and feedback from monitors. The trade-off is cost, complexity, and the isolated feeling that some musicians dislike. Many churches transition gradually — starting IEMs with the worship leader first.", tip: "Budget IEM systems work but have limited frequency response. Invest in decent earpieces — they make the biggest difference in sound quality.")
            ],
            tags: ["wedge", "iem", "monitors", "stage volume", "comparison"],
            relatedArticles: ["setting-up-iems", "preventing-feedback"]
        ),

        QAArticle(
            id: "monitor-routing-basics",
            title: "Monitor Routing on Your Console",
            category: .monitors,
            difficulty: .intermediate,
            summary: "How aux/bus sends work for monitor mixes and how to configure them on popular consoles.",
            sections: [
                QASection(heading: "Aux Sends Explained", content: "Each monitor mix uses an aux (auxiliary) bus. You send varying amounts of each channel to each aux bus to build individual mixes. Pre-fade sends are standard for monitors — this means the monitor level is independent of the FOH fader position, so your FOH mix changes do not affect what musicians hear.", tip: "Always use pre-fade sends for monitors. Post-fade sends are for effects (reverb, delay)."),
                QASection(heading: "Console-Specific Routing", content: "On the Avantis, use Mix buses configured as pre-fade for monitors. On the SQ, use Mix outputs 1-12. On the X32, Bus 1-16 can be set to pre-fade in the routing page. Label each bus by musician name for clarity during service. Most churches need 4-8 monitor mixes.", tip: "Set up a 'band leader' mix first — this becomes the template for other mixes with adjustments per musician.")
            ],
            tags: ["routing", "aux", "bus", "pre-fade", "monitors", "sends"],
            relatedArticles: ["setting-up-iems", "wedge-vs-iem"],
            consoleTags: ["avantis", "sq", "x32"]
        ),
    ]


    // MARK: - ─── Room Acoustics (3) ───────────────────────────────────────────

    private static let roomAcousticsArticles: [QAArticle] = [
        QAArticle(
            id: "understanding-rt60",
            title: "Understanding RT60",
            category: .roomAcoustics,
            difficulty: .intermediate,
            summary: "What RT60 means, how it affects your mix, and what your room's number tells you.",
            sections: [
                QASection(heading: "What Is RT60?", content: "RT60 (Reverberation Time 60) is the time it takes for a sound to decay by 60 dB after the source stops. A clap in an empty room that rings for 2 seconds has an RT60 of roughly 2 seconds. Shorter RT60 means a drier, more controlled room. Longer means more reverberant.", tip: nil),
                QASection(heading: "What's Ideal for Worship?", content: "For worship spaces that balance speech and music, an RT60 of 0.8-1.2 seconds is generally ideal. Below 0.8s, music can sound dry and lifeless. Above 1.5s, speech clarity suffers significantly. Many traditional churches sit at 1.5-3.0 seconds due to hard surfaces.", tip: "You can measure your room's RT60 using the Room Acoustics tool in this app."),
                QASection(heading: "How It Affects Your Mix", content: "In reverberant rooms: use less effects reverb (the room provides plenty), cut low-mids more aggressively (they build up), use tighter compression to control sustain, and keep the mix drier overall. In dry rooms: you have more freedom with effects and can let instruments ring out naturally.", tip: nil)
            ],
            tags: ["rt60", "reverb", "room", "acoustics", "decay", "treatment"],
            relatedArticles: []
        ),

        QAArticle(
            id: "acoustic-treatment-basics",
            title: "Acoustic Treatment Basics",
            category: .roomAcoustics,
            difficulty: .beginner,
            summary: "Types of acoustic treatment and where to place them to improve clarity in a worship space.",
            sections: [
                QASection(heading: "Absorption", content: "Absorptive panels reduce reflections by converting sound energy into heat. Place them at first reflection points — the walls and ceiling where sound bounces directly from speakers to the congregation. Common materials are rigid fiberglass panels or acoustic foam. Focus on the mid and high frequencies first.", tip: "Covering 15-25% of wall surface area with 2-inch absorptive panels can noticeably reduce RT60 and improve speech clarity."),
                QASection(heading: "Bass Traps and Diffusion", content: "Bass traps are thick absorbers placed in corners where low frequencies accumulate. They address the boominess that thin panels cannot. Diffusers scatter sound rather than absorbing it, keeping the room lively while reducing harsh reflections. A mix of absorption and diffusion is ideal for worship spaces.", tip: "Start with absorption for clarity, then add diffusion if the room feels too dead. Churches that over-treat with absorption lose the musical warmth the congregation expects.")
            ],
            tags: ["treatment", "absorption", "diffusion", "bass trap", "panels", "room"],
            relatedArticles: ["understanding-rt60", "mixing-in-reverberant-rooms"]
        ),

        QAArticle(
            id: "mixing-in-reverberant-rooms",
            title: "Mixing in Reverberant Rooms",
            category: .roomAcoustics,
            difficulty: .intermediate,
            summary: "Practical mix adjustments for highly reverberant worship spaces with long RT60 times.",
            sections: [
                QASection(heading: "EQ Adjustments", content: "In reverberant rooms, low-mid frequencies (200-500 Hz) build up the most. Cut this range more aggressively on all channels. Use steeper HPFs. Reduce or eliminate any effects reverb — the room is already adding plenty. Keep the mix tight and controlled.", tip: "A reverberant room adds its own EQ coloration. Listen from the congregation seating, not just the booth, to hear the true mix."),
                QASection(heading: "Dynamic and Source Control", content: "Use tighter compression to reduce the dynamic range — quiet-to-loud swings excite the room more. Keep stage volume as low as possible, since every dB of stage sound feeds the room's reverb. If possible, use directional speakers (line arrays) that focus sound on the congregation and minimize energy hitting walls and ceiling.", tip: "Reducing stage volume by switching from wedges to IEMs is often the single most impactful change in a reverberant room.")
            ],
            tags: ["reverberant", "rt60", "room", "eq", "low-mid", "stage volume"],
            relatedArticles: ["understanding-rt60", "acoustic-treatment-basics"]
        ),
    ]


    // MARK: - ─── Mixer Setup (6) ──────────────────────────────────────────────

    private static let mixerSetupArticles: [QAArticle] = [
        QAArticle(
            id: "avantis-getting-started",
            title: "Avantis: Getting Started",
            category: .mixerSetup,
            difficulty: .beginner,
            summary: "Initial Allen & Heath Avantis setup including input patching, channel naming, and scene basics.",
            sections: [
                QASection(heading: "Input Patching", content: "The Avantis uses 64 input channels with local I/O or a remote stage box (DX, GX, or dLive I/O). Patch inputs in the I/O screen — assign physical sockets to processing channels. Name each channel clearly (e.g., 'Lead Vox', 'Keys L') and assign colors for fast visual identification on the surface.", tip: "Use the Avantis Director software on a laptop to do initial setup before service day — it is faster than the touchscreen for bulk configuration."),
                QASection(heading: "Layers and Scenes", content: "Organize channels into layers by section: vocals on Layer A, band on Layer B, drums on Layer C. Store scenes for each service type — a scene recalls all settings. Use scene safes to protect settings you never want recalled (like gain and phantom power). Start with a 'template' scene as your base.", tip: "Always safe the preamp gain in your scene recall filter. Accidentally recalling gain during a live service can cause feedback or signal loss.")
            ],
            tags: ["avantis", "setup", "patching", "channels", "scenes", "layers"],
            relatedArticles: ["console-scene-management", "deep-processing-guide"],
            consoleTags: ["avantis"]
        ),

        QAArticle(
            id: "sq-getting-started",
            title: "SQ Series: Getting Started",
            category: .mixerSetup,
            difficulty: .beginner,
            summary: "Allen & Heath SQ setup covering I/O patching, channel strips, scenes, and SQ-Drive recording.",
            sections: [
                QASection(heading: "I/O and Channel Setup", content: "The SQ-5 has 48 channels with 16 local I/O plus optional stage boxes. Patch inputs from the I/O screen — the SQ uses a straightforward socket-to-channel assignment. Name channels, assign colors, and set up your HPF and phantom power during soundcheck. The touchscreen workflow is intuitive.", tip: "The SQ supports SQ-Drive for multitrack USB recording — plug in a USB drive and enable it for virtual soundcheck capability."),
                QASection(heading: "Scenes and Libraries", content: "Store scenes to recall your full setup. Use the scene recall filter to choose which parameters get recalled. Channel libraries let you save and recall individual channel strips (EQ, compression, gate) independently of full scenes — useful for saving your best vocal chain.", tip: "Use channel libraries for your go-to vocal and drum settings. They transfer between scenes and even between different SQ consoles.")
            ],
            tags: ["sq", "setup", "patching", "scenes", "library", "usb"],
            relatedArticles: ["console-scene-management", "avantis-getting-started"],
            consoleTags: ["sq"]
        ),

        QAArticle(
            id: "x32-getting-started",
            title: "X32/M32: Getting Started",
            category: .mixerSetup,
            difficulty: .beginner,
            summary: "Behringer X32 and Midas M32 setup covering routing, channel config, and scene management.",
            sections: [
                QASection(heading: "Routing and Inputs", content: "The X32/M32 has 32 input channels with local XLR inputs or digital stage boxes (S16, DL16). Configure routing in the Setup > Routing screen. The routing matrix is flexible but can be confusing — start with the default 1:1 mapping (input 1 to channel 1) and adjust as needed.", tip: "The X32-Edit software is free and lets you configure the entire console from a laptop. Use it for initial setup and as a backup."),
                QASection(heading: "Scenes and User Controls", content: "Scenes on the X32 store all console parameters. Use scene safes to protect channels or parameters from recall. The 'Cue' section lets you preview channels in headphones before bringing them into the mix. User-defined controls (encoders, buttons, faders) give quick access to frequently adjusted parameters.", tip: "Save a 'baseline' scene at the start of each service series, then create song-specific scenes that recall only EQ and effects changes.")
            ],
            tags: ["x32", "m32", "setup", "routing", "scenes", "behringer", "midas"],
            relatedArticles: ["console-scene-management"],
            consoleTags: ["x32", "m32"]
        ),

        QAArticle(
            id: "dlive-getting-started",
            title: "dLive: Getting Started",
            category: .mixerSetup,
            difficulty: .beginner,
            summary: "Allen & Heath dLive system setup including MixRack I/O, surface assignment, and processing.",
            sections: [
                QASection(heading: "System Architecture", content: "The dLive is a split system: the MixRack handles all I/O and processing, the Surface provides physical control. They connect via a single gigaACE Cat5e cable. Patch inputs from the MixRack I/O sockets to processing channels on the surface. The dLive supports up to 128 channels depending on configuration.", tip: "The dLive shares the XCVI processing engine with the Avantis. Settings and scenes from one can inform the other, though they are not directly compatible."),
                QASection(heading: "Processing Overview", content: "Every channel has a preamp, HPF/LPF, 4-band PEQ, gate, compressor, and insert point. DEEP processing (if licensed) adds vintage modeling. The dLive's processing is identical in quality to the Avantis — the main difference is scale and physical control surface options.", tip: "If your church uses both a dLive and Avantis (e.g., FOH and monitors), the same MIDI TCP protocol works on both for remote control.")
            ],
            tags: ["dlive", "mixrack", "surface", "setup", "gigaace", "processing"],
            relatedArticles: ["avantis-getting-started", "console-scene-management"],
            consoleTags: ["dlive"]
        ),

        QAArticle(
            id: "yamaha-tf-getting-started",
            title: "Yamaha TF: Getting Started",
            category: .mixerSetup,
            difficulty: .beginner,
            summary: "Yamaha TF series setup including GainFinder, 1-knob compressors, and TouchFlow operation.",
            sections: [
                QASection(heading: "TouchFlow Interface", content: "The Yamaha TF uses a touchscreen-first workflow called TouchFlow. Swipe through channel strips, tap to select, and use the touch faders for level control. The interface is designed for volunteers — it simplifies many operations that other consoles expose as separate controls.", tip: "The TF's gain range starts at -6 dB (not 0 dB like most consoles). This means you may see negative gain values — that is normal on Yamaha."),
                QASection(heading: "GainFinder and 1-Knob", content: "GainFinder is Yamaha's guided gain staging tool — it listens to the input signal and tells you which direction to turn the gain knob. The 1-knob compressor simplifies compression to a single control. These features are excellent for volunteer operators who do not have deep audio training.", tip: "While 1-knob compression is convenient, learning manual compression settings gives you much more control. Use 1-knob as a starting point and learn full settings over time.")
            ],
            tags: ["yamaha", "tf", "touchflow", "gainfinder", "1-knob", "setup"],
            relatedArticles: ["console-scene-management", "gain-staging-basics"],
            consoleTags: ["tf"]
        ),

        QAArticle(
            id: "console-scene-management",
            title: "Console Scene Management",
            category: .mixerSetup,
            difficulty: .intermediate,
            summary: "Scene recall strategies for worship: what to recall, safe parameters, and per-service vs per-song scenes.",
            sections: [
                QASection(heading: "What to Recall", content: "A scene stores your entire console state. But recalling everything mid-service is risky — you probably want to keep gain, phantom power, and monitor sends untouched. Use your console's scene recall filter (called 'safes' on A&H, 'recall filter' on X32) to protect critical parameters.", tip: "Always safe the preamp section (gain, pad, phantom) and monitor bus masters. These should only change during soundcheck, never during a live recall."),
                QASection(heading: "Scene Strategy", content: "Create a 'base' scene per service type (Sunday AM, Wednesday night, special event). Store song-specific scenes only for dramatic changes (e.g., stripped acoustic set vs full band). Keep it simple — most worship services need 1-2 scenes, not 15. Over-automating scenes creates more failure points than it solves.", tip: "Test every scene recall during rehearsal before using it live. A bad recall mid-service is worse than no recall at all.")
            ],
            tags: ["scenes", "recall", "safes", "filter", "management", "console"],
            relatedArticles: ["avantis-getting-started", "sq-getting-started", "x32-getting-started"],
            consoleTags: ["avantis", "sq", "dlive", "x32", "m32"]
        ),
    ]


    // MARK: - ─── Troubleshooting (5) ──────────────────────────────────────────

    private static let troubleshootingArticles: [QAArticle] = [
        QAArticle(
            id: "no-sound-checklist",
            title: "No Sound: Troubleshooting Checklist",
            category: .troubleshooting,
            difficulty: .beginner,
            summary: "Systematic checklist for diagnosing a 'no sound' situation, from mic to speaker.",
            sections: [
                QASection(heading: "Follow the Signal Chain", content: "Work from source to speaker: 1) Is the mic/DI plugged in and the cable good? 2) Is phantom power on (if condenser)? 3) Is the channel unmuted with gain up? 4) Is the fader up? 5) Is the channel assigned to the main bus? 6) Is the main fader up? 7) Are the amps/speakers powered on? Check each step in order.", tip: "Nine times out of ten, it is a muted channel, an unplugged cable, or a powered-off stage box. Start with the simple things."),
                QASection(heading: "Quick Isolation Test", content: "Use the console's solo/AFL button to listen to the channel in headphones. If you hear signal in solo but not in the PA, the problem is downstream — bus routing, main fader, or amplifier. If you hear nothing in solo, the problem is upstream — cable, preamp, or mic.", tip: "Always have a known-good XLR cable and a spare SM58 at the booth for quick swap testing.")
            ],
            tags: ["no sound", "troubleshooting", "signal chain", "mute", "checklist"],
            relatedArticles: ["channel-crackling", "gain-staging-basics"]
        ),

        QAArticle(
            id: "ground-loop-hum",
            title: "Fixing Ground Loop Hum",
            category: .troubleshooting,
            difficulty: .intermediate,
            summary: "Diagnosing and eliminating the persistent 60 Hz hum caused by ground loops in your audio system.",
            sections: [
                QASection(heading: "What Is a Ground Loop?", content: "A ground loop occurs when two pieces of audio equipment are connected to different electrical ground points. The voltage difference between the grounds creates a 60 Hz hum (50 Hz in some countries) that rides on the audio signal. It is a steady, low-pitched buzz that does not change with fader level.", tip: "Ground loop hum is constant regardless of input signal. If the hum changes when you adjust the gain, it is probably not a ground loop — it is more likely a cable or interference issue."),
                QASection(heading: "How to Fix It", content: "The first solution to try is the ground lift switch on DI boxes — this disconnects the cable shield at one end, breaking the loop. If using direct connections, try a ground lift adapter or an isolation transformer. Ensure all audio equipment is on the same electrical circuit when possible.", tip: "Never defeat the safety ground on power cables (the three-prong to two-prong adapter trick). This is a fire and shock hazard. Use proper audio ground lifts instead.")
            ],
            tags: ["ground loop", "hum", "60hz", "buzz", "ground lift", "di"],
            relatedArticles: ["no-sound-checklist", "channel-crackling"]
        ),

        QAArticle(
            id: "channel-crackling",
            title: "Diagnosing Crackling Audio",
            category: .troubleshooting,
            difficulty: .beginner,
            summary: "Finding and fixing crackling, popping, or intermittent audio caused by cables, connections, or digital issues.",
            sections: [
                QASection(heading: "Cable and Connector Issues", content: "The most common cause of crackling is a damaged cable or loose connection. Wiggle each cable at the connector while listening — if the crackling changes, you found it. XLR connectors wear out over time, especially on stage where they get stepped on. Replace suspect cables immediately.", tip: "Label your cables and keep a log of which ones cause problems. A $10 cable tester saves hours of troubleshooting."),
                QASection(heading: "Digital Clock and Phantom Power", content: "On digital consoles, crackling can indicate a clock sync issue between the console and an external stage box or audio interface. Ensure all digital devices share the same word clock source. Crackling on condenser mics can also mean a failing phantom power supply — test by moving the mic to a different channel.", tip: "If crackling appears on all channels simultaneously, suspect the digital clock, power supply, or main output connection rather than individual channels.")
            ],
            tags: ["crackling", "popping", "cable", "digital", "clock", "troubleshooting"],
            relatedArticles: ["no-sound-checklist", "ground-loop-hum"]
        ),

        QAArticle(
            id: "console-latency-issues",
            title: "Managing Console Latency",
            category: .troubleshooting,
            difficulty: .intermediate,
            summary: "Understanding digital console latency and its impact on in-ear monitor mixes and recordings.",
            sections: [
                QASection(heading: "What Causes Latency", content: "Digital consoles convert analog audio to digital, process it, then convert back — this takes time. Typical console latency is 1-3 ms. Additional processing (DEEP/FX inserts) and network-connected stage boxes add more. While 1-3 ms is inaudible for FOH, musicians using IEMs may notice latency above 5 ms as a 'comb filter' effect on their own voice.", tip: "The Avantis has approximately 0.7 ms of base latency — among the lowest in its class. This makes it excellent for IEM workflows."),
                QASection(heading: "Reducing Latency Impact", content: "Minimize plugin inserts on IEM monitor sends. Use local I/O instead of network stage boxes for critical IEM channels when possible. On the X32, using the AES50 connection to an S16 stage box adds about 0.5 ms. Test latency by having a vocalist sing into their IEMs and listen for any hollow or phasing artifacts.", tip: "If a vocalist complains their voice sounds 'weird' in their IEMs, latency is often the culprit. A small amount of ambient room mic blended in can mask the effect.")
            ],
            tags: ["latency", "delay", "digital", "iem", "processing", "clock"],
            relatedArticles: ["setting-up-iems", "console-scene-management"],
            consoleTags: ["x32", "m32", "avantis"]
        ),

        QAArticle(
            id: "wireless-mic-dropouts",
            title: "Wireless Mic Dropouts",
            category: .troubleshooting,
            difficulty: .intermediate,
            summary: "Managing wireless microphone interference, frequency coordination, and antenna placement.",
            sections: [
                QASection(heading: "Common Causes", content: "Wireless mic dropouts are usually caused by: RF interference from other wireless devices, poor antenna placement, low transmitter batteries, or too many wireless systems on overlapping frequencies. The more wireless channels you run, the more careful your frequency coordination needs to be.", tip: "Replace wireless mic batteries before every service, even if they show charge remaining. A dropout during the sermon is never worth saving a battery."),
                QASection(heading: "Antenna and Frequency Tips", content: "Place receiver antennas in line-of-sight with the stage, away from metal objects and other electronics. Use antenna distribution systems when running more than 4 wireless channels. Run a frequency scan on your receivers before service to identify clean frequencies. Space your wireless frequencies at least 500 kHz apart.", tip: "On A&H consoles with Dante or local I/O, patch wireless receivers as close to the console as possible to minimize cable runs from antenna to receiver.")
            ],
            tags: ["wireless", "dropout", "rf", "antenna", "frequency", "interference"],
            relatedArticles: ["no-sound-checklist", "channel-crackling"],
            consoleTags: ["avantis", "sq"]
        ),
    ]


    // MARK: - ─── Advanced Techniques (4) ──────────────────────────────────────

    private static let advancedTechniqueArticles: [QAArticle] = [
        QAArticle(
            id: "parallel-compression",
            title: "Parallel Compression Technique",
            category: .advancedTechniques,
            difficulty: .advanced,
            summary: "Using parallel (New York) compression on vocals and drums for punch without losing dynamics.",
            sections: [
                QASection(heading: "The Concept", content: "Parallel compression blends a heavily compressed copy of a signal with the original uncompressed signal. The result retains the natural dynamics and transients of the original while adding the body, sustain, and density of the compressed copy. It gives you the best of both worlds.", tip: "Set up an aux send to a bus with heavy compression (8:1 ratio, low threshold, 10+ dB of gain reduction), then blend that bus back into the mix underneath the dry channel."),
                QASection(heading: "Worship Applications", content: "Parallel compression is excellent on a drum subgroup — it thickens the kit without squashing the snare transients. On vocals, it adds body to quiet passages without affecting the dynamics of powerful worship moments. Start with the compressed bus fader low and bring it up until you hear the added density.", tip: "A common mistake is too much parallel compression, which sounds muddy and over-processed. If you can clearly hear the effect, pull it back.")
            ],
            tags: ["parallel", "new york", "compression", "advanced", "bus", "technique"],
            relatedArticles: ["what-does-compressor-do", "compression-settings"]
        ),

        QAArticle(
            id: "multiband-compression",
            title: "Multiband Compression",
            category: .advancedTechniques,
            difficulty: .advanced,
            summary: "When and how to use multiband compression on vocals and the master bus for frequency-specific dynamics control.",
            sections: [
                QASection(heading: "How It Works", content: "Multiband compression splits the audio into frequency bands (typically 3-4) and applies independent compression to each band. This lets you control the dynamics of the low end without affecting the highs, or tame vocal sibilance without compressing the entire voice.", tip: "A common use is on the master bus: gentle compression on the low band (below 200 Hz) keeps bass tight while leaving the mid and high bands more dynamic."),
                QASection(heading: "When to Use It", content: "Multiband compression is powerful but complex — use it only when standard compression and EQ cannot solve the problem. Good scenarios: a vocalist whose low-end rumble is inconsistent (compress just the lows), a bass guitar that booms on certain notes but not others, or a master bus that needs tighter low end without affecting vocal dynamics.", tip: "In worship mixing, multiband compression is rarely needed on individual channels. Standard EQ and compression handle 95% of situations. Reserve multiband for master bus polish.")
            ],
            tags: ["multiband", "compression", "advanced", "bus", "frequency", "dynamics"],
            relatedArticles: ["parallel-compression", "compressor-vs-limiter"]
        ),

        QAArticle(
            id: "gain-sharing-technique",
            title: "Gain Sharing on A&H Consoles",
            category: .advancedTechniques,
            difficulty: .advanced,
            summary: "Using gain sharing/tracking when multiple engineers share an Allen & Heath I/O rack for FOH and monitors.",
            sections: [
                QASection(heading: "What Is Gain Sharing", content: "Gain sharing allows two consoles (e.g., FOH Avantis and monitor dLive) to share the same I/O rack. One console is the 'gain master' and controls the preamp. The other console uses a digital trim to adjust its level without affecting the shared preamp. This prevents the monitor engineer's gain changes from disrupting the FOH mix.", tip: "On A&H systems, the console connected to Port A of the I/O rack is typically the gain master. Confirm this in the I/O configuration before service."),
                QASection(heading: "Workflow Tips", content: "Communicate with the other engineer during soundcheck about gain changes. The gain master should set preamps while the other engineer adjusts their digital trim. Once gain is set, neither engineer should touch the preamp without alerting the other. Label which console is the gain master clearly in your documentation.", tip: "If you are the non-master console, your digital trim has the same effect as gain for your mix — but it only exists in the digital domain and does not affect the other console.")
            ],
            tags: ["gain sharing", "tracking", "split", "foh", "monitors", "io rack"],
            relatedArticles: ["avantis-getting-started", "dlive-getting-started"],
            consoleTags: ["avantis", "dlive"]
        ),

        QAArticle(
            id: "virtual-soundcheck",
            title: "Virtual Soundcheck",
            category: .advancedTechniques,
            difficulty: .advanced,
            summary: "Setting up and running a virtual soundcheck using multitrack recording playback through your console.",
            sections: [
                QASection(heading: "What Is Virtual Soundcheck", content: "Virtual soundcheck lets you play back a multitrack recording of a previous service through your console as if the band were playing live. Each recorded channel feeds back into its corresponding console input. This allows you to tweak your mix without the band present — saving rehearsal time and giving you unlimited practice.", tip: "Record a full service multitrack as early as possible. Once you have one, you can practice mixing any time the room is empty."),
                QASection(heading: "Setup Requirements", content: "You need a multitrack recording device (USB drive on SQ, Dante virtual soundcard on Avantis, X-USB card on X32) and a DAW or playback device. Route the playback outputs back to the console inputs, overriding the live mic signals. Make sure to switch back to live inputs before the actual service starts.", tip: "Label your virtual soundcheck scene clearly and distinctly from your live scene. Accidentally recalling the VSC routing during a live service sends recorded audio instead of live mics.")
            ],
            tags: ["virtual soundcheck", "multitrack", "recording", "playback", "rehearsal"],
            relatedArticles: ["console-scene-management", "avantis-getting-started"]
        ),
    ]
}
