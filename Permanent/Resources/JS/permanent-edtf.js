/* Permanent's Swift-facing surface. One global, strings in, JSON strings out. */
(function (global) {
  var M = __require("edtf");
  var EDate = M.Date, Interval = M.Interval, Bitmask = M.Bitmask, parseEDTF = M.default;

  var SCOPE = { year: Bitmask.Y, month: Bitmask.M, day: Bitmask.D };
  /* A qualifier on the whole date covers only the positions it has: 1984? is Y, 1984-06? is YM. */
  var WHOLE = [0, Bitmask.Y, Bitmask.YM, Bitmask.YMD];
  var UNSPEC = { none: 0, day: Bitmask.D, monthDay: Bitmask.MD };

  function fail(message) { return { ok: false, error: message }; }

  /* One endpoint of a date or interval. month and day arrive 1-based; edtf.js wants month 0-based. */
  function buildOne(p, label) {
    if (p === null || typeof p !== "object") return fail(label + " is missing");
    if (typeof p.year !== "number") return fail(label + " needs a year");

    var values = [p.year];
    if (typeof p.month === "number") {
      if (p.month < 1 || p.month > 12) return fail(label + " month must be 1 to 12");
      values.push(p.month - 1);
      if (typeof p.day === "number") {
        if (p.day < 1 || p.day > 31) return fail(label + " day must be 1 to 31");
        values.push(p.day);
      }
    } else if (typeof p.day === "number") {
      return fail(label + " has a day but no month");
    }

    var unspecified = UNSPEC[p.unspecified || "none"];
    if (unspecified === undefined) return fail(label + " has an unknown unspecified value");
    // An X only renders at a position that carries a value, so pad before applying the mask.
    if (unspecified) { while (values.length < 3) values.push(1); }

    var d = new EDate(values);
    if (unspecified) d.unspecified.value = unspecified;

    var scope = (p.scope || "all") === "all" ? WHOLE[values.length] : SCOPE[p.scope];
    if (scope === undefined) return fail(label + " has an unknown scope");
    if ((p.scope === "month" && values.length < 2) || (p.scope === "day" && values.length < 3)) {
      return fail(label + " has a qualifier on a part it does not have");
    }
    if (p.uncertain === true) d.uncertain.value = scope;
    if (p.approximate === true) d.approximate.value = scope;

    return { ok: true, node: d };
  }

  /* Accepts one endpoint, or {start, end} where either side may be "open" or "unknown". */
  function build(parts) {
    if (parts === null || typeof parts !== "object") return fail("no parts given");
    if (!parts.start && !parts.end) {
      var single = buildOne(parts, "date");
      return single.ok ? { ok: true, node: single.node } : single;
    }

    var ends = [null, null];
    var names = ["start", "end"];
    for (var i = 0; i < 2; i++) {
      var side = parts[names[i]];
      // "1984/" carries a null end; "1984/.." carries an infinite one. Do not merge these.
      if (side === "open") { ends[i] = null; continue; }
      if (side === "unknown") { ends[i] = i === 0 ? -Infinity : Infinity; continue; }
      var built = buildOne(side, names[i]);
      if (!built.ok) return built;
      ends[i] = built.node;
    }
    return { ok: true, node: new Interval(ends) };
  }

  /* Every value this returns is date precision or coarser, so it is byte-stable in any timezone. */
  function format(partsJSON) {
    var parts;
    try { parts = JSON.parse(partsJSON); } catch (e) { return JSON.stringify(fail("parts are not valid JSON")); }
    var result;
    try { result = build(parts); } catch (e) { return JSON.stringify(fail(String(e && e.message || e))); }
    if (!result.ok) return JSON.stringify(result);
    var text;
    try { text = result.node.edtf; } catch (e) { return JSON.stringify(fail(String(e && e.message || e))); }
    return JSON.stringify({ ok: true, edtf: text });
  }

  /* A datetime with no zone is rewritten to UTC using the device timezone, so it is refused here. */
  function validate(text) {
    if (typeof text !== "string" || text === "") return JSON.stringify(fail("empty string"));
    if (/T\d{2}:\d{2}/.test(text) && !/(Z|[+-]\d{2}:?\d{2})$/.test(text)) {
      return JSON.stringify(fail("a datetime must carry Z or an explicit offset"));
    }
    var node;
    try { node = parseEDTF(text); } catch (e) { return JSON.stringify(fail(String(e && e.message || e))); }
    return JSON.stringify({ ok: true, edtf: node.edtf, type: node.type });
  }

  /* Round-trips a stored string back into the fields the editing screen holds. */
  function decompose(text) {
    var node;
    try { node = parseEDTF(text); } catch (e) { return JSON.stringify(fail(String(e && e.message || e))); }
    try {
      if (node.type === "Interval") {
        return JSON.stringify({ ok: true, parts: { start: endpoint(node.lower), end: endpoint(node.upper) } });
      }
      return JSON.stringify({ ok: true, parts: endpoint(node) });
    } catch (e) { return JSON.stringify(fail(String(e && e.message || e))); }
  }

  /* Throws for anything the parts cannot hold, so a season or a time is refused, not misread. */
  function endpoint(node) {
    if (node === null) return "open";
    if (typeof node === "number") return "unknown";
    if (node.type !== "Date") throw new Error("a " + node.type + " cannot be edited as date parts");
    var values = node.values || [];
    if (!values.length) return "unknown";
    if (values.length > 3) throw new Error("a time cannot be edited as date parts");
    var unspecified = maskName(node.unspecified && node.unspecified.value);
    if (unspecified === "other") throw new Error("these unspecified digits cannot be edited as date parts");
    var out = { year: values[0] };
    // A masked position holds only the padding this bridge added, so do not hand it back.
    if (values.length > 1 && unspecified !== "monthDay") out.month = values[1] + 1;
    if (values.length > 2 && unspecified === "none") out.day = values[2];
    var uncertain = (node.uncertain && node.uncertain.value) || 0;
    var approximate = (node.approximate && node.approximate.value) || 0;
    if (uncertain && approximate && uncertain !== approximate) {
      throw new Error("two qualifiers on different parts cannot be edited as date parts");
    }
    out.uncertain = !!uncertain;
    out.approximate = !!approximate;
    out.scope = scopeName(uncertain || approximate, node.precision);
    out.unspecified = unspecified;
    return out;
  }

  /* The "all" mask depends on precision: year-only is Y, month is YM, day is YMD. */
  function scopeName(mask, precision) {
    if (!mask) return "all";
    if (mask === WHOLE[precision || 3]) return "all";
    if (mask === Bitmask.Y) return "year";
    if (mask === Bitmask.M) return "month";
    if (mask === Bitmask.D) return "day";
    throw new Error("this qualifier position cannot be edited as date parts");
  }

  function maskName(value) {
    if (!value) return "none";
    if (value === Bitmask.MD) return "monthDay";
    if (value === Bitmask.D) return "day";
    return "other";
  }

  global.PermanentEDTF = { format: format, validate: validate, decompose: decompose };
})(globalThis);
