import SwiftUI

#if os(macOS)
struct MacTagGrid: View {
    let tags: [PyokoTag]
    @Binding var selectedTags: [PyokoTag]
    @State private var search = ""

    private var matches: [PyokoTag] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? tags : tags.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            TextField("Find a tag", text: $search)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("tags.search")
                .frame(maxWidth: 380)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 14)], alignment: .leading, spacing: 12) {
                ForEach(matches) { tag in
                    Toggle(tag.name, isOn: Binding(
                        get: { selectedTags.contains { $0.id == tag.id } },
                        set: { enabled in
                            var updated = selectedTags.filter { $0.id != tag.id }
                            if enabled { updated.append(tag) }
                            selectedTags = updated
                        }))
                        .accessibilityIdentifier("tag.\(tag.name)")
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .accessibilityIdentifier("tags.grid")
            if matches.isEmpty {
                Text("No tags match your search.").foregroundStyle(.secondary)
            }
        }
    }
}
#endif
