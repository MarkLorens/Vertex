import SwiftUI

/// Single source of truth for colour, type, spacing, radius and elevation.
enum DesignTokens {}

// MARK: - Palette

extension DesignTokens {

    /// Raw colour values. Prefer the semantic names in `DesignTokens.Colors`;
    /// reach for these only when a semantic token genuinely doesn't exist yet.
    enum Palette {

        // MARK: Terracotta — the brand ramp (oklch hue 42)

        /// `oklch(0.63 0.14 42)` · `#CE683F` — the colour field itself, and the primary button.
        static let terracotta = Color(p3: 0.7549, 0.4303, 0.2844)
        /// `oklch(0.55 0.15 42)` · `#B64C1B` — icons and eyebrow labels on cream.
        static let terracottaDeep = Color(p3: 0.6652, 0.3244, 0.1662)
        /// `oklch(0.50 0.15 42)` · `#A63D02` — links and inline emphasis on cream.
        static let terracottaInk = Color(p3: 0.6014, 0.2653, 0.1016)
        /// `oklch(0.45 0.14 42)` · `#913100` — the darkest readable terracotta, for headline accents.
        static let terracottaShade = Color(p3: 0.5265, 0.2194, 0.0647)
        /// `oklch(0.28 0.05 42)` · `#3D2014` — near-black warm brown, used for a solid pill on cream.
        static let terracottaDeepest = Color(p3: 0.2248, 0.1308, 0.0887)
        /// `oklch(0.95 0.03 42)` · `#FFE9DF` — the "Needs you" pill ground.
        static let terracottaTint = Color(p3: 0.9925, 0.9153, 0.8802)
        /// `oklch(0.50 0.10 30)` · `#944B40` — desaturated field for the cancel-vote screen (3h).
        static let terracottaMuted = Color(p3: 0.5420, 0.3093, 0.2645)

        // MARK: Warm neutrals — authored as sRGB hex in the doc

        /// `#17140F` — the ink the whole cream side is built on.
        static let ink = Color(hex: 0x17140F)
        /// `#FBF8F4` — the cream sheet that rises over the colour field.
        static let cream = Color(hex: 0xFBF8F4)
        /// Pure white — cards and fields sitting on the cream sheet.
        static let paper = Color.white
        /// `oklch(0.97 0.008 60)` · `#F9F4F0` — faintest warm fill.
        static let warmGrey100 = Color(p3: 0.9741, 0.9573, 0.9423)
        /// `oklch(0.96 0.012 60)` · `#F8F0EA` — subtle warm fill.
        static let warmGrey200 = Color(p3: 0.9677, 0.9426, 0.9201)
        /// `oklch(0.93 0.01 60)` · `#EDE6E1` — empty avatar / overflow chip.
        static let warmGrey300 = Color(p3: 0.9252, 0.9045, 0.8859)

        // MARK: Green — a yes vote, a met condition (oklch hue 145)

        /// `oklch(0.93 0.05 145)` · `#D4F1D4` — "Lock it in" pill ground.
        static let greenTint = Color(p3: 0.8534, 0.9429, 0.8399)
        /// `oklch(0.96 0.02 145)` · `#EAF6EA` — faintest green wash.
        static let greenTintFaint = Color(p3: 0.9257, 0.9618, 0.9201)
        /// `oklch(0.70 0.14 145)` · `#61B565` — the up-vote button, filled strength bars.
        static let green = Color(p3: 0.4613, 0.7014, 0.4301)
        /// `oklch(0.60 0.15 145)` · `#3A9742` — status dot.
        static let greenDot = Color(p3: 0.3300, 0.5828, 0.2993)
        /// `oklch(0.55 0.13 145)` · `#38853E` — mid green.
        static let greenMid = Color(p3: 0.3008, 0.5137, 0.2744)
        /// `oklch(0.48 0.12 145)` · `#286F2F` — deep green.
        static let greenDeep = Color(p3: 0.2363, 0.4276, 0.2131)
        /// `oklch(0.44 0.11 145)` · `#236228` — green text on cream ("Strong", "You're in").
        static let greenInk = Color(p3: 0.2063, 0.3778, 0.1855)
        /// `oklch(0.42 0.11 145)` · `#1C5C23` — green text on a green tint.
        static let greenInkDeep = Color(p3: 0.1848, 0.3554, 0.1645)

        // MARK: Amber — a maybe (oklch hue 80)

        /// `oklch(0.83 0.11 80)` · `#EDBF71` — the "maybe" segment of a vote bar.
        static let amber = Color(p3: 0.9007, 0.7576, 0.4875)

        // MARK: Red — a no vote, a destructive action (oklch hue 25–27)

        /// `oklch(0.95 0.02 27)` · `#FCEAE7` — destructive button ground.
        static let redTint = Color(p3: 0.9754, 0.9192, 0.9091)
        /// `oklch(0.86 0.06 27)` · `#F6C3BC` — destructive button border.
        static let redTintBorder = Color(p3: 0.9336, 0.7714, 0.7438)
        /// `oklch(0.60 0.17 27)` · `#D24D45` — the down-vote button when it's the cast vote.
        static let red = Color(p3: 0.7647, 0.3379, 0.2938)
        /// `oklch(0.53 0.19 27)` · `#C22826` — destructive label text.
        static let redInk = Color(p3: 0.6979, 0.2150, 0.1850)
        /// `oklch(0.60 0.20 25)` · `#DE3B3D` — the unread count badge.
        static let redBadge = Color(p3: 0.8045, 0.2869, 0.2686)

        // MARK: Avatars

        /// The eight avatar hues — `oklch(0.66 0.13 h)` for h in 20…320.
        /// One lightness and one chroma, so no member of a group reads louder
        /// than another. Index by a stable hash of the person, not by position.
        static let avatar: [Color] = [
            Color(p3: 0.7864, 0.4550, 0.4519), // h20  · #D66F71
            Color(p3: 0.7814, 0.4736, 0.3499), // h40  · #D47452
            Color(p3: 0.6723, 0.5603, 0.2020), // h90  · #B18E15
            Color(p3: 0.4273, 0.6468, 0.3986), // h145 · #5AA75E
            Color(p3: 0.2087, 0.6516, 0.6874), // h200 · #00A9B1
            Color(p3: 0.4146, 0.5699, 0.8580), // h258 · #5E93E1
            Color(p3: 0.6025, 0.5003, 0.8155), // h300 · #9F7ED6
            Color(p3: 0.6745, 0.4748, 0.7483), // h320 · #B576C3
        ]
    }
}

// MARK: - Semantic colour

extension DesignTokens {

    /// Semantic colour. Two contexts exist and they don't mix: `on…` names are
    /// for content over the terracotta field, everything else is for content on
    /// the cream sheet.
    enum Colors {

        // MARK: Surfaces

        /// The full-bleed terracotta ground every screen starts from.
        static let field = Palette.terracotta
        /// The desaturated field reserved for the cancel-event vote (3h).
        static let fieldDanger = Palette.terracottaMuted
        /// The cream sheet that rises over the field with `Radius.sheet` top corners.
        static let sheet = Palette.cream
        /// Cards and input fields on the sheet.
        static let card = Palette.paper
        /// An avatar with no image behind it.
        static let avatarEmpty = Palette.warmGrey300

        // MARK: Ink — content on the cream sheet

        /// Titles, row labels, values. `#17140F`.
        static let ink = Palette.ink
        /// Secondary text that still needs to be read easily.
        static let inkStrong = Palette.ink.opacity(0.70)
        /// Body copy and supporting sentences.
        static let inkSecondary = Palette.ink.opacity(0.50)
        /// Row subtitles, vote tallies.
        static let inkTertiary = Palette.ink.opacity(0.45)
        /// Captions, fine print, disclaimers.
        static let inkMuted = Palette.ink.opacity(0.42)
        /// Uppercase field labels.
        static let inkSubtle = Palette.ink.opacity(0.40)
        /// Icon strokes and the "OR" rule label.
        static let inkFaint = Palette.ink.opacity(0.35)
        /// Placeholder text in an empty field.
        static let inkPlaceholder = Palette.ink.opacity(0.32)

        // MARK: Lines and fills on the cream sheet

        /// Hairline rules and dividers.
        static let separator = Palette.ink.opacity(0.10)
        /// Resting border on a card or input.
        static let border = Palette.ink.opacity(0.12)
        /// Border on a white button that needs more definition.
        static let borderStrong = Palette.ink.opacity(0.14)
        /// The unfilled remainder of a progress or vote bar.
        static let track = Palette.ink.opacity(0.09)
        /// A resting icon button, e.g. an uncast vote.
        static let fill = Palette.ink.opacity(0.06)
        /// The faintest fill, and the card shadow's colour.
        static let fillSubtle = Palette.ink.opacity(0.05)

        // MARK: On the terracotta field

        /// Headlines and primary-button labels over the field.
        static let onField = Color.white
        /// Nav titles over the field.
        static let onFieldStrong = Color.white.opacity(0.90)
        /// Supporting labels over the field.
        static let onFieldSecondary = Color.white.opacity(0.80)
        /// Sub-headlines under a hero title.
        static let onFieldMuted = Color.white.opacity(0.72)
        /// The wordmark, and quiet metadata over the field.
        static let onFieldSubtle = Color.white.opacity(0.65)
        /// Deselected state over the field.
        static let onFieldFaint = Color.white.opacity(0.45)
        /// The unfilled remainder of a progress bar over the field.
        static let onFieldTrack = Color.white.opacity(0.25)
        /// A translucent surface over the field.
        static let onFieldSurface = Color.white.opacity(0.16)

        // MARK: Actions

        /// The primary button, and the focus ring on a field.
        static let accent = Palette.terracotta
        /// The primary button when it sits on the sheet rather than the field.
        static let accentOnSheet = Palette.terracottaDeep
        /// Links and inline emphasis on the sheet.
        static let accentInk = Palette.terracottaInk
        /// An icon paired with `accentInk` text — one step lighter, because a
        /// 2.6pt stroke reads heavier than text at the same size. Used on the
        /// secondary button and the selected tab.
        static let accentIcon = Palette.terracottaDeep
        /// The ground behind an accent pill, e.g. "Needs you".
        static let accentTint = Palette.terracottaTint
        /// A selected slot on the availability grid — the field at 35%.
        static let accentSelected = Palette.terracotta.opacity(0.35)
        /// The high-contrast alternative to the accent button ("Continue with Apple", "Finish voting").
        static let actionInk = Palette.ink

        // MARK: Status

        /// A yes vote, a satisfied requirement.
        static let positive = Palette.green
        /// Positive text on the sheet.
        static let positiveInk = Palette.greenInk
        /// Positive text on `positiveTint`.
        static let positiveInkOnTint = Palette.greenInkDeep
        /// The ground behind a positive pill.
        static let positiveTint = Palette.greenTint
        /// A live positive status dot.
        static let positiveDot = Palette.greenDot

        /// A maybe — the middle segment of a vote bar.
        static let maybe = Palette.amber

        /// A no vote.
        static let negative = Palette.red
        /// Destructive label text ("Decline invitation", "Cancel event").
        static let negativeInk = Palette.redInk
        /// The ground behind a destructive button.
        static let negativeTint = Palette.redTint
        /// The border on a destructive button.
        static let negativeTintBorder = Palette.redTintBorder

        /// The unread count badge on the tab bar.
        static let badge = Palette.redBadge
    }
}

// MARK: - Typography

extension DesignTokens {

    /// A font paired with the tracking the design specifies for it. SwiftUI
    /// carries tracking on the view rather than the font, so apply both with
    /// `.textStyle(_:)`.
    struct TextStyle {
        let font: Font
        let tracking: CGFloat
        /// Extra leading in points. Zero for everything but the display sizes,
        /// where the doc sets a line-height below 1.0 — tighten those with a
        /// negative value or a custom layout at the call site.
        let lineSpacing: CGFloat

        init(_ font: Font, tracking: CGFloat = 0, lineSpacing: CGFloat = 0) {
            self.font = font
            self.tracking = tracking
            self.lineSpacing = lineSpacing
        }
    }

    /// The type ramp. SF Pro throughout, at fixed sizes — the design is laid
    /// out to the point and doesn't reflow, so these deliberately don't scale
    /// with Dynamic Type. Swap `.system(size:weight:)` for
    /// `.custom(_:size:relativeTo:)` if that changes.
    ///
    /// The doc uses variable weights (620, 640, 650, 660, 680). Those collapse
    /// onto SwiftUI's named weights here; the original is noted per style.
    enum Typography {

        // MARK: Display — countdown numerals, tabular

        /// 150pt / bold / -9 · line-height 0.86. The oversized numeral on the empty colour field.
        static let countdownHero = TextStyle(.system(size: 150, weight: .bold), tracking: -9)
        /// 104pt / ultraLight (250) / -5. The airiest countdown treatment.
        static let countdownXLarge = TextStyle(.system(size: 104, weight: .ultraLight), tracking: -5)
        /// 80pt / bold / -4 · line-height 0.90.
        static let countdownLarge = TextStyle(.system(size: 80, weight: .bold), tracking: -4)
        /// 76pt / semibold (660) / -4 · line-height 0.86.
        static let countdownMedium = TextStyle(.system(size: 76, weight: .semibold), tracking: -4)
        /// 52pt / semibold (640) / -2.4. The per-unit clock digits.
        static let countdownSmall = TextStyle(.system(size: 52, weight: .semibold), tracking: -2.4)
        /// 40pt / bold / -1.6. A single emphatic number in a card.
        static let numeral = TextStyle(.system(size: 40, weight: .bold), tracking: -1.6)
        /// 34pt / semibold (600) / -0.6. The unit suffix beside a hero numeral ("d").
        static let countdownUnit = TextStyle(.system(size: 34, weight: .semibold), tracking: -0.6)
        /// 30pt / semibold (600) / -0.6. The hours/minutes/seconds line under the hero numeral.
        static let countdownSecondary = TextStyle(.system(size: 30, weight: .semibold), tracking: -0.6)

        // MARK: Titles

        /// 34pt / bold / -0.9 · line-height 1.08. The largest hero headline.
        static let titleXLarge = TextStyle(.system(size: 34, weight: .bold), tracking: -0.9)
        /// 32pt / bold / -0.8 · line-height 1.1. The standard screen headline over the field.
        static let titleLarge = TextStyle(.system(size: 32, weight: .bold), tracking: -0.8)
        /// 30pt / bold / -0.7 · line-height 1.12. Section headline.
        static let title = TextStyle(.system(size: 30, weight: .bold), tracking: -0.7)
        /// 26pt / semibold (680) / -0.6. Card headline.
        static let titleSmall = TextStyle(.system(size: 26, weight: .semibold), tracking: -0.6)
        /// 23pt / semibold (680) / -0.5 · line-height 1.2. Event name on a card.
        static let headline = TextStyle(.system(size: 23, weight: .semibold), tracking: -0.5)
        /// 22pt / bold / -0.8 · line-height 1.05. The tightest headline.
        static let headlineTight = TextStyle(.system(size: 22, weight: .bold), tracking: -0.8)

        // MARK: Rows, buttons and body

        /// 17pt / bold / -0.35. The title line of a list row.
        static let rowTitle = TextStyle(.system(size: 17, weight: .bold), tracking: -0.35)
        /// 17pt / semibold (660) / -0.3. The label on a full-width button.
        static let button = TextStyle(.system(size: 17, weight: .semibold), tracking: -0.3)
        /// 17pt / semibold (600) / -0.2. The line introducing a hero title ("Three sleeps until").
        static let lede = TextStyle(.system(size: 17, weight: .semibold), tracking: -0.2)
        /// 16.5pt / semibold (680) / -0.3. Emphasised body.
        static let bodyLargeStrong = TextStyle(.system(size: 16.5, weight: .semibold), tracking: -0.3)
        /// 16.5pt / regular / -0.3. Field values and long-form body.
        static let bodyLarge = TextStyle(.system(size: 16.5, weight: .regular), tracking: -0.3)
        /// 16pt / semibold / -0.2. Nav bar title.
        static let navTitle = TextStyle(.system(size: 16, weight: .semibold), tracking: -0.2)
        /// 16pt / medium (500) / -0.2. Body.
        static let body = TextStyle(.system(size: 16, weight: .medium), tracking: -0.2)
        /// 16pt / regular / -0.2 · line-height 1.5. The explanatory paragraph
        /// under an empty-state headline. Wraps at 300pt in the doc.
        static let paragraph = TextStyle(.system(size: 16, weight: .regular), tracking: -0.2, lineSpacing: 5)
        /// 15.5pt / regular / -0.2. The sub-headline under a hero title.
        static let subtitle = TextStyle(.system(size: 15.5, weight: .regular), tracking: -0.2)
        /// 15pt / semibold (650) / -0.2. Emphasised callout.
        static let calloutStrong = TextStyle(.system(size: 15, weight: .semibold), tracking: -0.2)
        /// 15pt / medium (550) / -0.2. Callout.
        static let callout = TextStyle(.system(size: 15, weight: .medium), tracking: -0.2)
        /// 14.5pt / semibold (650) / -0.2. The label on a half-width button.
        static let footnoteStrong = TextStyle(.system(size: 14.5, weight: .semibold), tracking: -0.2)
        /// 14.5pt / regular / -0.2. Footnote.
        static let footnote = TextStyle(.system(size: 14.5, weight: .regular), tracking: -0.2)
        /// 14pt / semibold (650) / -0.1. An inline text action ("Nudge", "Plan").
        static let link = TextStyle(.system(size: 14, weight: .semibold), tracking: -0.1)
        /// 14pt / regular / -0.2. A supporting line under a card's content.
        static let footnoteSmall = TextStyle(.system(size: 14, weight: .regular), tracking: -0.2)

        // MARK: Captions

        /// 13.5pt / semibold (650) / -0.1. Emphasised caption, e.g. a pill label.
        static let captionStrong = TextStyle(.system(size: 13.5, weight: .semibold), tracking: -0.1)
        /// 13.5pt / regular / -0.1. The most common supporting line.
        static let caption = TextStyle(.system(size: 13.5, weight: .regular), tracking: -0.1)
        /// 13pt / regular / -0.1 · line-height 1.4. Fine print and disclaimers.
        static let caption2 = TextStyle(.system(size: 13, weight: .regular), tracking: -0.1)
        /// 12.5pt / semibold (620) / 0. The smallest emphasised label, e.g. a status pill.
        /// The "OR" rule label is the one place the doc adds +0.3 tracking.
        static let caption3 = TextStyle(.system(size: 12.5, weight: .semibold))
        /// 11.5pt / semibold (650) / 0. Initials inside an avatar.
        static let avatarInitials = TextStyle(.system(size: 11.5, weight: .semibold))

        // MARK: Uppercase labels — set the text uppercased at the call site

        /// 15pt / semibold (650) / +2.4, uppercase. The Vertex wordmark.
        /// (5a sets +3; +2.4 is the repeated value across the doc.)
        static let wordmark = TextStyle(.system(size: 15, weight: .semibold), tracking: 2.4)
        /// 11.5pt / bold / +0.9, uppercase. The label above an input field.
        static let eyebrow = TextStyle(.system(size: 11.5, weight: .bold), tracking: 0.9)
        /// 10.5pt / semibold / +0.6, uppercase. The smallest label, e.g. a date chip's month.
        static let eyebrowSmall = TextStyle(.system(size: 10.5, weight: .semibold), tracking: 0.6)

        // MARK: Tab bar

        /// 10pt / medium (500). A resting tab label.
        static let tabLabel = TextStyle(.system(size: 10, weight: .medium))
        /// 10pt / semibold (650). The selected tab label, and the badge count.
        static let tabLabelSelected = TextStyle(.system(size: 10, weight: .semibold))
    }
}

extension View {
    /// Applies a `DesignTokens.TextStyle` — font, tracking and leading together.
    ///
    /// `.tracking()` also shortens the last character's advance, which pulls the
    /// text's layout width in under its own ink and crops the final glyph. At
    /// body sizes that loss is under a point and never shows; at display sizes
    /// it visibly slices the last character, so use `TextStyle.text(_:)` there.
    func textStyle(_ style: DesignTokens.TextStyle) -> some View {
        self.font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}

extension DesignTokens.TextStyle {
    /// The same style with tracking applied *between* characters only, so the
    /// final glyph keeps its natural advance and renders uncropped. Required
    /// for the display sizes, where tracking runs to -9.
    func text(_ string: String) -> some View {
        var attributed = AttributedString(string)
        let characters = attributed.characters
        if tracking != 0,
           characters.count > 1,
           let lastCharacter = characters.index(
               attributed.startIndex,
               offsetBy: characters.count - 1,
               limitedBy: attributed.endIndex
           ) {
            attributed[attributed.startIndex..<lastCharacter].kern = tracking
        }
        return Text(attributed)
            .font(font)
            .lineSpacing(lineSpacing)
    }
}

// MARK: - Spacing

extension DesignTokens {

    /// The spacing scale. Everything in the doc lands on these values.
    enum Spacing {
        /// 2pt — the gap between segments of a vote bar.
        static let xxs: CGFloat = 2
        /// 4pt
        static let xs: CGFloat = 4
        /// 6pt
        static let sm: CGFloat = 6
        /// 8pt
        static let md: CGFloat = 8
        /// 10pt — the gap between stacked cards and buttons.
        static let lg: CGFloat = 10
        /// 12pt
        static let xl: CGFloat = 12
        /// 14pt
        static let xxl: CGFloat = 14
        /// 16pt
        static let xxxl: CGFloat = 16
        /// 20pt
        static let huge: CGFloat = 20
        /// 24pt
        static let xhuge: CGFloat = 24
        /// 30pt
        static let xxhuge: CGFloat = 30
    }

    /// Layout constants that aren't part of the general scale.
    enum Layout {
        /// 20pt — horizontal padding inside the cream sheet.
        static let sheetPadding: CGFloat = 20
        /// 22pt — the wider sheet padding used on the auth screens.
        static let sheetPaddingWide: CGFloat = 22
        /// 20pt — the screen gutter for a header row over the field.
        static let screenPadding: CGFloat = 20
        /// 24pt — horizontal padding for content sitting directly on the field.
        static let fieldPadding: CGFloat = 24
        /// 26pt — the roomier gutter the hero block uses on the field.
        static let heroPadding: CGFloat = 26
        /// 16pt — internal padding of a card.
        static let cardPadding: CGFloat = 16
        /// 15pt — internal padding of a field or a compact card.
        static let controlPadding: CGFloat = 15
        /// 22pt — the sheet's own top padding, below its rounded corners.
        static let sheetTopPadding: CGFloat = 22
        /// 30pt — the gap between the last control and the bottom of the sheet.
        static let sheetBottomPadding: CGFloat = 30
        /// 56pt — top inset for a screen with a nav row over the field.
        static let fieldTopInset: CGFloat = 56
        /// 60pt — the standard top inset over the field.
        static let fieldTopInsetLarge: CGFloat = 60
    }
}

// MARK: - Radius

extension DesignTokens {

    enum Radius {
        /// 2pt — the smallest rounding, on tick marks.
        static let xs: CGFloat = 2
        /// 9pt — progress and vote bars.
        static let bar: CGFloat = 9
        /// 12pt — chips and small tiles.
        static let chip: CGFloat = 12
        /// 14pt — input fields and compact buttons.
        static let field: CGFloat = 14
        /// 17pt — the full-width primary button.
        static let button: CGFloat = 17
        /// 20pt — cards on the cream sheet.
        static let card: CGFloat = 20
        /// 30pt — the sheet's top corners.
        static let sheet: CGFloat = 30
        /// 48pt — the device frame, for previews.
        static let device: CGFloat = 48
        /// Fully rounded — pills, avatars, dots.
        static let pill: CGFloat = 999
    }
}

// MARK: - Size

extension DesignTokens {

    enum Size {
        /// 1pt — dividers and rules.
        static let hairline: CGFloat = 1
        /// 54pt — the full-width primary button.
        static let buttonHeight: CGFloat = 54
        /// 52pt — a full-width secondary button (the social sign-in row).
        static let buttonHeightSecondary: CGFloat = 52
        /// 48pt — a half-width button.
        static let buttonHeightCompact: CGFloat = 48
        /// 50pt — an input field.
        static let fieldHeight: CGFloat = 50
        /// 44pt — a circular vote button, and the minimum tap target.
        static let voteButton: CGFloat = 44
        /// 34pt — a pill-shaped action.
        static let pillHeight: CGFloat = 34
        /// 30pt — a compact chip.
        static let chipHeight: CGFloat = 30
        /// 28pt — an inline status pill.
        static let chipHeightSmall: CGFloat = 28
        /// 83pt — the tab bar.
        static let tabBarHeight: CGFloat = 83

        /// Avatar diameters. The stack overlaps by `avatarOverlap`.
        enum Avatar {
            /// 22pt — inside a dense row.
            static let small: CGFloat = 22
            /// 24pt — the standard stacked avatar.
            static let medium: CGFloat = 24
            /// 28pt — on the colour field.
            static let large: CGFloat = 28
            /// 30pt — on the cream sheet.
            static let xlarge: CGFloat = 30
            /// 44pt — a single avatar in a dialogue.
            static let hero: CGFloat = 44
            /// -7pt overlap for `small`/`medium`, -9pt for `large`/`xlarge`.
            static let overlap: CGFloat = -7
            static let overlapLarge: CGFloat = -9
            /// 1.5pt ring in the sheet's colour, so overlapping avatars stay separable.
            static let ringWidth: CGFloat = 1.5
        }

        /// Bar heights, thickest to thinnest.
        enum Bar {
            /// 6pt — the "5 of 7 voted" progress bar over the field.
            static let progress: CGFloat = 6
            /// 5pt — the vote-split bar on a card.
            static let vote: CGFloat = 5
            /// 4pt — the password strength meter.
            static let strength: CGFloat = 4
        }
    }
}

// MARK: - Elevation

extension DesignTokens {

    /// A shadow, in SwiftUI's terms. CSS blur is halved to get SwiftUI's radius.
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    enum Elevation {
        /// The only shadow in the committed screens: a card on the cream sheet.
        /// CSS `0 1px 2px rgba(23,20,15,.05)`.
        static let card = Shadow(color: Colors.fillSubtle, radius: 1, x: 0, y: 1)
        /// A sheet lifting off the screen. CSS `0 1px 2px rgba(0,0,0,.05), 0 8px 24px rgba(0,0,0,.05)`.
        static let sheet = Shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 8)
        /// A modal over a dimmed screen. CSS `0 24px 60px rgba(0,0,0,.3)`.
        static let modal = Shadow(color: .black.opacity(0.30), radius: 30, x: 0, y: 24)
    }
}

extension View {
    /// Applies a `DesignTokens.Shadow`.
    func shadow(_ shadow: DesignTokens.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Colour construction

private extension Color {

    /// The design doc's warm neutrals are authored as sRGB hex.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// The doc's `oklch()` colours, resolved into Display P3 so the ones that
    /// fall outside sRGB keep their chroma.
    init(p3 red: Double, _ green: Double, _ blue: Double) {
        self.init(.displayP3, red: red, green: green, blue: blue)
    }
}
