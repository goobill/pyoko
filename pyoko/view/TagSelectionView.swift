//
//  TagSelectionView.swift
//  pyoko
//
//  Created by Bill on 07/09/2026.
//

import SwiftUI

struct TagSelectionView: View {

    let title: String

    let tags:
        [PyokoTag]

    @Binding
    var selectedTags:
        [PyokoTag]

    let emptySelectionMessage:
        String?

    init(
        title: String = "Tags",
        tags: [PyokoTag],
        selectedTags: Binding<[PyokoTag]>,
        emptySelectionMessage: String? = nil
    ) {

        self.title =
            title

        self.tags =
            tags

        self._selectedTags =
            selectedTags

        self.emptySelectionMessage =
            emptySelectionMessage
    }

    var body: some View {

        GroupBox(
            title
        ) {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                controls

                Divider()

                if tags.isEmpty {

                    Text(
                        "No tags are available."
                    )
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    tagList
                }

                if let emptySelectionMessage,
                   selectedTags.isEmpty {

                    Text(
                        emptySelectionMessage
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }
        }
    }

    // MARK: - Controls

    private var controls:
        some View {

        HStack(
            spacing: 12
        ) {

            Text(
                selectionText
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )

            Spacer()

            Button(
                "Select All"
            ) {

                selectAll()
            }
            .buttonStyle(
                .borderless
            )
            .disabled(
                tags.isEmpty
                || allSelected
            )
            .accessibilityIdentifier("tags.all")

            Button(
                "Deselect All"
            ) {

                deselectAll()
            }
            .buttonStyle(
                .borderless
            )
            .disabled(
                selectedTags.isEmpty
            )
            .accessibilityIdentifier("tags.none")
        }
    }

    // MARK: - Tags

    private var tagList:
        some View {

        VStack(
            spacing: 10
        ) {

            ForEach(
                tags
            ) { tag in

                Toggle(
                    tag.name,
                    isOn:
                        Binding(
                            get: {

                                isSelected(
                                    tag
                                )
                            },
                            set: {

                                setSelected(
                                    tag,
                                    selected:
                                        $0
                                )
                            }
                        )
                )
                .accessibilityIdentifier("tag.\(tag.name)")
            }
        }
    }

    // MARK: - Selection

    private var selectedTagIDs:
        Set<UUID> {

        Set(
            selectedTags.map(
                \.id
            )
        )
    }

    private var allSelected:
        Bool {

        guard !tags.isEmpty
        else {
            return false
        }

        let allTagIDs =
            Set(
                tags.map(
                    \.id
                )
            )

        return allTagIDs
            .isSubset(
                of:
                    selectedTagIDs
            )
    }

    private var selectionText:
        String {

        let selectedCount =
            tags.filter {
                selectedTagIDs
                    .contains(
                        $0.id
                    )
            }
            .count

        return
            "\(selectedCount) of \(tags.count) selected"
    }

    private func isSelected(
        _ tag: PyokoTag
    ) -> Bool {

        selectedTagIDs
            .contains(
                tag.id
            )
    }

    private func setSelected(
        _ tag: PyokoTag,
        selected: Bool
    ) {

        var updated =
            selectedTags

        if selected {

            guard !updated.contains(
                where: {
                    $0.id == tag.id
                }
            )
            else {
                return
            }

            updated.append(
                tag
            )

        } else {

            updated.removeAll {
                $0.id == tag.id
            }
        }

        selectedTags =
            updated
    }

    private func selectAll() {

        selectedTags =
            tags
    }

    private func deselectAll() {

        selectedTags =
            []
    }
}
