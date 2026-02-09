// ============================================================================
// AppTips.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: TipKit Definitions
// Purpose: Contextual tips shown throughout the app to guide new users.
//          Each tip appears once (or weekly) to teach key workflows.
// ============================================================================

import TipKit


// MARK: - ─── Services Tab Tips ──────────────────────────────────────────────

/// Shown on the Services tab when no services exist yet.
struct CreateServiceTip: Tip {
    var title: Text {
        Text("Create Your First Service")
    }
    var message: Text? {
        Text("Start by setting up a service for this Sunday with your band, setlist, and room details.")
    }
    var image: Image? {
        Image(systemName: "music.note.list")
    }
}


// MARK: - ─── Inputs Tab Tips ────────────────────────────────────────────────

/// Shown on the Inputs tab on first visit.
struct InputLibraryTip: Tip {
    var title: Text {
        Text("Your Input Library")
    }
    var message: Text? {
        Text("Inputs from your services are saved here automatically. You can also add custom channels and vocalist profiles.")
    }
    var image: Image? {
        Image(systemName: "pianokeys")
    }
}


// MARK: - ─── Consoles Tab Tips ──────────────────────────────────────────────

/// Shown on the Consoles tab on first visit.
struct ConsoleConnectTip: Tip {
    var title: Text {
        Text("Add Your Console")
    }
    var message: Text? {
        Text("Add your mixer to import settings via CSV or connect live over TCP/MIDI.")
    }
    var image: Image? {
        Image(systemName: "slider.horizontal.below.rectangle")
    }
}


// MARK: - ─── Tools Tab Tips ─────────────────────────────────────────────────

/// Shown on the Tools tab on first visit.
struct SPLMeterTip: Tip {
    var title: Text {
        Text("SPL Meter")
    }
    var message: Text? {
        Text("Calibrate the SPL meter at your mix position for accurate sound level monitoring during services.")
    }
    var image: Image? {
        Image(systemName: "speaker.wave.2.fill")
    }
}
