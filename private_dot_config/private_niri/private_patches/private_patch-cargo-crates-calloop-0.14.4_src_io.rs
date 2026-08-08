--- cargo-crates/calloop-0.14.4/src/io.rs.orig	2026-08-02 21:18:40.958339000 +0200
+++ cargo-crates/calloop-0.14.4/src/io.rs	2026-08-02 21:18:40.988070000 +0200
@@ -221,6 +221,17 @@
     }
 
     fn kill(&self, dispatcher: &RefCell<IoDispatcher>) {
+        // Drop the poller registration as well. polling's kqueue backend keeps its
+        // own set of registered fds, so a number left in it is refused forever after.
+        #[cfg(unix)]
+        {
+            let disp = dispatcher.borrow();
+            let _ = self
+                .poll
+                .borrow_mut()
+                .unregister(unsafe { BorrowedFd::borrow_raw(disp.fd) });
+        }
+
         let token = dispatcher
             .borrow()
             .token
