#ifndef PPO_BRIDGE_IO_H
#define PPO_BRIDGE_IO_H
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Private, same-UID mailbox. Caller closes the directory descriptor.
 * Directory must be mode 0700; parent must already exist. Does not chmod.
 * Payloads are regular, mode-0600, single-link files owned by getuid().
 * Only request.json, response.json, heartbeat.json and consumed.json allowed.
 * Reads and writes accept at most 4096 bytes. Write size must be nonzero.
 * OpenDirectory returns an fd, or -1 with errno. Other functions return
 * zero on success or a positive errno value. Read sets *length only on success.
 * All functions are blocking I/O and belong on a worker, never UIKit's main queue.
 */
enum { PPOBridgeMaximumBytes = 4096 };
int PPOBridgeOpenDirectory(const char *path);
int PPOBridgeWrite(int directory, const char *name, const void *bytes, size_t length);
int PPOBridgeRead(int directory, const char *name, void *bytes, size_t capacity, size_t *length);

#ifdef __cplusplus
}
#endif
#endif
