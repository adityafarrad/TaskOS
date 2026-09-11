import Foundation

@MainActor
final class FileSystemChangeMonitor {
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private var watchedDirectories: Set<String> = []
    private var debounceTask: Task<Void, Never>?

    var onChange: (() -> Void)?

    func update(directories: Set<String>) {
        guard directories != watchedDirectories else { return }

        for (_, source) in sources {
            source.cancel()
        }
        sources.removeAll()
        watchedDirectories = directories

        for directory in directories {
            let descriptor = open(directory, O_EVTONLY)
            guard descriptor >= 0 else { continue }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: descriptor,
                eventMask: [.write, .delete, .rename, .attrib],
                queue: .main
            )
            source.setEventHandler { [weak self] in
                MainActor.assumeIsolated {
                    self?.scheduleRefresh()
                }
            }
            source.setCancelHandler {
                close(descriptor)
            }
            source.resume()
            sources[directory] = source
        }
    }

    func stop() {
        for (_, source) in sources {
            source.cancel()
        }
        sources.removeAll()
        watchedDirectories = []
        debounceTask?.cancel()
        debounceTask = nil
    }

    private func scheduleRefresh() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.onChange?()
        }
    }
}
