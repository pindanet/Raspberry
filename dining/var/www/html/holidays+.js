function berekenPasen(jaar) {
  const a = jaar % 19;
  const b = Math.floor(jaar / 100);
  const c = jaar % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);

  const maand = Math.floor((h + l - 7 * m + 114) / 31);
  const dag = ((h + l - 7 * m + 114) % 31) + 1;

  return new Date(jaar, maand - 1, dag);
}

function voegDagenToe(datum, dagen) {
  const resultaat = new Date(datum);
  resultaat.setDate(resultaat.getDate() + dagen);
  return resultaat;
}

function haalAlleFeestdagenOp(jaar) {
  const pasen = berekenPasen(jaar);

  const dagen = [
    // Wettelijke feestdagen (Federaal)
    { naam: 'Nieuwjaar', datum: new Date(jaar, 0, 1), type: 'wettelijk' },
    { naam: 'Paasmaandag', datum: voegDagenToe(pasen, 1), type: 'wettelijk' },
    { naam: 'Dag v.d. Arbeid', datum: new Date(jaar, 4, 1), type: 'wettelijk' },
    { naam: 'O.L.H-Hemelvaart', datum: voegDagenToe(pasen, 39), type: 'wettelijk' },
    { naam: 'Pinkstermaandag', datum: voegDagenToe(pasen, 50), type: 'wettelijk' },
    { naam: 'Nationale feestdag', datum: new Date(jaar, 6, 21), type: 'wettelijk' },
    { naam: 'O.L.V.-Hemelvaart', datum: new Date(jaar, 7, 15), type: 'wettelijk' },
    { naam: 'Allerheiligen', datum: new Date(jaar, 10, 1), type: 'wettelijk' },
    { naam: 'Wapenstilstand', datum: new Date(jaar, 10, 11), type: 'wettelijk' },
    { naam: 'Kerstmis', datum: new Date(jaar, 11, 25), type: 'wettelijk' },

    // Gewestelijke en gemeenschapsfeestdagen
    { naam: 'Vlaamse Gemeenschap', datum: new Date(jaar, 6, 11), type: 'gewestelijk' },
    { naam: 'Waals Gewest', datum: new Date(jaar, 8, 20), type: 'gewestelijk' }, // 3e zondag van sept (zie onder)
    { naam: 'Franse Gemeenschap', datum: new Date(jaar, 8, 27), type: 'gewestelijk' },
    { naam: 'Duitstalige Gemeenschap', datum: new Date(jaar, 10, 15), type: 'gewestelijk' },

    // Niet-wettelijke / gangbare vrije dagen (bv. banken, overheid, scholen)
    { naam: 'Goede Vrijdag', datum: voegDagenToe(pasen, -2), type: 'niet-wettelijk' },
    { naam: 'Pasen', datum: pasen, type: 'niet-wettelijk' },
    { naam: 'Pinksteren', datum: voegDagenToe(pasen, 49), type: 'niet-wettelijk' },
    { naam: 'Allerzielen', datum: new Date(jaar, 10, 2), type: 'niet-wettelijk' },
    { naam: 'Koningsdag', datum: new Date(jaar, 10, 15), type: 'niet-wettelijk' },
    { naam: 'Tweede Kerstdag', datum: new Date(jaar, 11, 26), type: 'niet-wettelijk' },

    // Verjaardagen
    { naam: '1966 Luc &#127874;', datum: new Date(jaar, 0, 23), type: 'verjaardag' },
    { naam: '1933 Ma 2014', datum: new Date(jaar, 2, 4), type: 'verjaardag' },
    { naam: '1960 Dany &#127874;', datum: new Date(jaar, 2, 28), type: 'verjaardag' },
    { naam: '1931 Pa 2020', datum: new Date(jaar, 7, 1), type: 'verjaardag' },
    { naam: '1996 Roos &#127874;', datum: new Date(jaar, 7, 8), type: 'verjaardag' },
    { naam: '1998 Elke &#127874;', datum: new Date(jaar, 8, 22), type: 'verjaardag' },
    { naam: '1961 Peter &#127874;', datum: new Date(jaar, 10, 29), type: 'verjaardag' }

  ];

  // Correctie voor het Feest van het Waals Gewest (altijd de derde zondag van september)
  const waalsFeest = dagen.find(d => d.naam === 'Waals Gewest');
  const eersteSept = new Date(jaar, 8, 1);
  const dagVanDeWeek = eersteSept.getDay(); // 0 = zondag
  const dagenTotEersteZondag = dagVanDeWeek === 0 ? 0 : 7 - dagVanDeWeek;
  waalsFeest.datum = new Date(jaar, 8, 1 + dagenTotEersteZondag + 14);

  return dagen.sort((a, b) => a.datum - b.datum);
}
