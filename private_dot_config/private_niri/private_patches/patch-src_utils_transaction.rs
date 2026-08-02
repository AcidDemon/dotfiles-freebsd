--- src/utils/transaction.rs.orig
+++ src/utils/transaction.rs
@@ -88,7 +88,7 @@
         if let Deadline::NotRegistered(deadline) = *cell {
             let timer = Timer::from_deadline(deadline);
             let inner = Arc::downgrade(&self.inner);
-            let token = event_loop
+            let token = match event_loop
                 .insert_source(timer, move |_, _, _| {
                     let _span = trace_span!("deadline timer", transaction = ?Weak::as_ptr(&inner))
                         .entered();
@@ -107,16 +107,32 @@
 
                     TimeoutAction::Drop
                 })
-                .unwrap();
+            {
+                Ok(token) => token,
+                Err(err) => {
+                    // Losing the deadline can stall a resize. Aborting loses the session.
+                    warn!("error registering deadline timer: {err:?}");
+                    return;
+                }
+            };
 
             // Add a ping source that will be used to remove the timer automatically.
-            let (ping, source) = make_ping().unwrap();
+            let (ping, source) = match make_ping() {
+                Ok(ping) => ping,
+                Err(err) => {
+                    warn!("error creating deadline ping: {err:?}");
+                    event_loop.remove(token);
+                    return;
+                }
+            };
             let loop_handle = event_loop.clone();
-            event_loop
-                .insert_source(source, move |_, _, _| {
-                    loop_handle.remove(token);
-                })
-                .unwrap();
+            if let Err(err) = event_loop.insert_source(source, move |_, _, _| {
+                loop_handle.remove(token);
+            }) {
+                warn!("error registering deadline ping: {err:?}");
+                event_loop.remove(token);
+                return;
+            }
 
             *cell = Deadline::Registered { remove: ping };
         }
