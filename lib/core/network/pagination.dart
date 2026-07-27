/// Helpers for the DRF-style pagination envelope the backend returns:
///
/// ```json
/// { "count": 40, "next": ".../category/?page=2", "previous": null,
///   "results": [ ... ] }
/// ```
///
/// WHY THIS MATTERS
/// ----------------
/// The server paginates at a fixed 25 items and ignores `page_size`, `limit`
/// and `per_page`. Reading only `results` therefore silently truncates every
/// list to its first 25 entries — which is how a catalogue of 40 categories
/// was rendering as 25, and how a category with 46 products was showing 25.
///
/// Any caller of a paginated endpoint must keep requesting `?page=N` until
/// `next` is null.
library;

/// Safety valve for the "keep following `next`" loops.
///
/// At 25 items per page this allows 2500 items per list, far more than the
/// catalogue holds. It exists purely so a server that always returns a
/// non-null `next` cannot spin the client forever.
const int kMaxPagesPerFetch = 100;

/// Reads the `next` link out of a decoded pagination envelope.
///
/// Returns null when the payload is not an envelope (some endpoints return a
/// bare list) or when there are no further pages.
String? nextPageLink(Object? payload) {
  if (payload is Map) {
    final next = payload['next'];
    if (next is String && next.isNotEmpty) return next;
  }
  return null;
}

/// Reads the total `count` out of a decoded pagination envelope, if present.
int? totalCount(Object? payload) {
  if (payload is Map) {
    final count = payload['count'];
    if (count is int) return count;
  }
  return null;
}
