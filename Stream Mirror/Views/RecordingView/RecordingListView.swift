//
//  RecordingListView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct RecordingListView: View {

    @ObservedObject var recordingVM: ScreenRecordingViewModel
        
    var body: some View {

        ZStack {

            VStack {

                CommonStatusView(
                    title: str.MyRecoding,
                    isCastingShow: false
                )

                if recordingVM.recordings.isEmpty {

                    Spacer()

                    placeholderView(
                        image: "RecordinglistPH",
                        title: str.NoRecordingsYet,
                        title2: "",
                        isTitle2: false
                    )

                    Spacer()

                } else {

                    ScrollView(showsIndicators: false) {

                        LazyVStack(spacing: 12) {

                            ForEach(recordingVM.recordings) { recording in

                                RecordingLisRow(
                                    image: "recording",
                                    fileName: recording.name,
                                    fileSize: recording.date.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    ),
                                    shareAction: {

                                        recordingVM.shareItem =
                                            ShareItem(
                                                url: recording.url
                                            )
                                    },
                                    deleteAction: {

                                        recordingVM.deleteRecording(
                                            recording
                                        )
                                    },
                                    buttonAction: {
                                        recordingVM.selectedRecording = recording
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }

                Spacer()
            }
        }
        .appScreen()
        .sheet(item: $recordingVM.shareItem) { item in
            DrawingShareSheet(
                activityItems: [item.url]
            )
        }
        .sheet(item: $recordingVM.selectedRecording) { recording in
            VideoPlayerView(url: recording.url)
        }
        .onAppear {
            recordingVM.loadScreenRecordings()
        }
    }
}


#Preview {
    RecordingListView(recordingVM: ScreenRecordingViewModel())
}
