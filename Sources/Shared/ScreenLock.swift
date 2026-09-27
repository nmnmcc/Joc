// SPDX-License-Identifier: GPL-2.0-only

#if os(macOS)
    import Darwin

    enum ScreenLock {
        private typealias LockFunction = @convention(c) () -> Void

        static func lock() -> Bool {
            let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"

            guard let handle = dlopen(path, RTLD_NOW | RTLD_LOCAL) else {
                return false
            }

            guard let symbol = dlsym(handle, "SACLockScreenImmediate") else {
                dlclose(handle)
                return false
            }

            let lockScreen = unsafeBitCast(symbol, to: LockFunction.self)
            lockScreen()

            dlclose(handle)
            return true
        }
    }
#endif
