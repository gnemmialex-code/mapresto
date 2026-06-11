/// Outil de migration : insère tous les lieux dans Supabase.
///
/// Usage :
///   dart run tools/seed_supabase.dart \
///     --url=https://XXXX.supabase.co \
///     --key=YOUR_SERVICE_ROLE_KEY
///
/// La SERVICE ROLE KEY (pas l'anon key) se trouve dans
///   Supabase Dashboard → Settings → API → service_role
///
/// L'outil utilise uniquement dart:io + dart:convert (aucune dépendance).
library;
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  // -- Lecture des arguments --
  String? url, key;
  for (final a in args) {
    if (a.startsWith('--url=')) url = a.substring(6);
    if (a.startsWith('--key=')) key = a.substring(6);
  }
  if (url == null || key == null) {
    print('Usage: dart run tools/seed_supabase.dart --url=<URL> --key=<SERVICE_ROLE_KEY>');
    exit(1);
  }

  final places = _buildPlaces();
  print('🚀 Envoi de ${places.length} lieux vers Supabase...');

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$url/rest/v1/places'),
    );
    request.headers
      ..set('apikey', key)
      ..set('Authorization', 'Bearer $key')
      ..set('Content-Type', 'application/json')
      ..set('Prefer', 'resolution=merge-duplicates');
    request.write(jsonEncode(places));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✓ ${places.length} lieux insérés/mis à jour avec succès!');
    } else {
      print('✗ Erreur HTTP ${response.statusCode}:\n$body');
    }
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// Données : tous les lieux de l'app (doit rester synchronisé avec
// mock_data_service.dart). On stocke uniquement les champs "bruts" ;
// les champs dérivés (averagePrice, crowdTags, etc.) sont calculés côté app.
// ---------------------------------------------------------------------------
List<Map<String, dynamic>> _buildPlaces() => [
  // ===================== BARS =====================
  _p('p01','Le Perchoir Marais','bar',48.8629,2.3640,'33 Rue de la Verrerie, 75004 Paris',4.5,1820,3,['chic','festif','branché'],['house','lounge'],['rooftop','cocktails','vue Tour Eiffel']),
  _p('p02','Little Red Door','bar',48.8632,2.3622,'60 Rue Charlot, 75003 Paris',4.7,940,3,['chic','intimiste'],['jazz','lounge'],['speakeasy','cocktails']),
  _p('p03','Bar Hemingway (Ritz)','bar',48.8681,2.3284,'15 Place Vendome, 75001 Paris',4.6,1200,4,['chic','business','intimiste'],['jazz'],['speakeasy','cocktails'],true),
  _p('p04','Le Comptoir General','bar',48.8704,2.3672,'80 Quai de Jemmapes, 75010 Paris',4.3,5600,2,['festif','décontracté','insolite'],['afro','house'],['terrasse','cocktails']),
  _p('p05','Le Bar du Plaza Athenee','bar',48.8662,2.3036,'25 Avenue Montaigne, 75008 Paris',4.5,880,4,['chic','romantique','business'],['lounge'],['cocktails'],true),
  _p('p06','Candelaria','bar',48.8627,2.3661,'52 Rue de Saintonge, 75003 Paris',4.4,2100,3,['branché','animé'],['latino','house'],['speakeasy','cocktails','mexicain']),
  _p('p07','Le Syndicat','bar',48.8718,2.3530,'51 Rue du Faubourg Saint-Denis, 75010 Paris',4.5,1300,3,['branché','intimiste'],['soul','funk'],['cocktails','speakeasy']),
  _p('p08','Experimental Cocktail Club','bar',48.8662,2.3486,'37 Rue Saint-Sauveur, 75002 Paris',4.4,1750,3,['animé','branché'],['house','funk'],['cocktails','speakeasy']),
  _p('p09','La Belle Hortense','bar',48.8570,2.3588,'31 Rue Vieille du Temple, 75004 Paris',4.3,640,2,['cosy','intimiste'],['jazz'],['vins nature','bistrot']),
  _p('p10','Septime La Cave','bar',48.8537,2.3805,'3 Rue Basfroi, 75011 Paris',4.5,720,2,['cosy','branché'],['lounge'],['vins nature']),
  _p('p11','BrewDog Paris','bar',48.8602,2.3705,'11 Rue Amelot, 75011 Paris',4.2,2400,2,['décontracté','animé'],['rock','pop'],['bière artisanale','terrasse']),
  _p('p12','Rosa Bonheur','bar',48.8800,2.3830,'2 Allee de la Cascade, 75019 Paris',4.2,6200,2,['festif','familial','décontracté'],['pop','latino'],['terrasse','jardin']),
  _p('p13','Rex Club','bar',48.8704,2.3470,'5 Boulevard Poissonniere, 75002 Paris',4.4,3800,3,['festif','animé'],['techno','house'],['club']),
  _p('p14','Sacre Rooftop','bar',48.8867,2.3431,'18e arrondissement, 75018 Paris',4.2,410,2,['festif','romantique'],['house','pop'],['rooftop','terrasse','vue Tour Eiffel'],true),
  _p('p15','Cravan','bar',48.8556,2.3401,'17 Rue Jean de la Fontaine, 75016 Paris',4.6,520,3,['chic','romantique'],['jazz','lounge'],['speakeasy','cocktails']),
  _p('p16','Bisou','bar',48.8615,2.3672,'15 Boulevard du Temple, 75003 Paris',4.5,980,2,['branché','intimiste'],['soul'],['cocktails']),
  // ===================== RESTAURANTS =====================
  _p('p17','Septime','restaurant',48.8536,2.3819,'80 Rue de Charonne, 75011 Paris',4.6,3100,4,['chic','romantique','branché'],['lounge'],['gastronomique','terrasse'],true),
  _p('p18','Bouillon Pigalle','restaurant',48.8823,2.3375,'22 Boulevard de Clichy, 75018 Paris',4.4,14800,1,['festif','familial','décontracté'],['pop'],['bistrot','brunch']),
  _p('p19','Le Jules Verne','restaurant',48.8582,2.2945,'Tour Eiffel Avenue Gustave Eiffel, 75007 Paris',4.5,2200,4,['chic','romantique','business'],['lounge'],['gastronomique','vue Tour Eiffel'],true),
  _p('p20','Holybelly 5','restaurant',48.8717,2.3592,'5 Rue Lucien Sampaix, 75010 Paris',4.5,4300,2,['cosy','décontracté'],['pop','soul'],['brunch']),
  _p('p21','Clamato','restaurant',48.8534,2.3812,'80 Rue de Charonne, 75011 Paris',4.4,1500,3,['cosy','branché'],['jazz'],['fruits de mer','vins nature']),
  _p('p22','Le Relais de l\'Entrecote','restaurant',48.8707,2.3076,'15 Rue Marbeuf, 75008 Paris',4.2,9200,2,['business','animé'],['lounge'],['steakhouse']),
  _p('p23','Brasserie Lipp','restaurant',48.8540,2.3331,'151 Boulevard Saint-Germain, 75006 Paris',4.1,5200,3,['business','chic'],['jazz'],['brasserie','terrasse']),
  _p('p24','East Mamma','restaurant',48.8519,2.3782,'133 Rue du Faubourg Saint-Antoine, 75011 Paris',4.4,11200,2,['animé','familial','festif'],['pop'],['italien','pizza']),
  _p('p25','Pink Mamma','restaurant',48.8819,2.3375,'20bis Rue de Douai, 75009 Paris',4.5,13900,3,['branché','animé'],['pop','soul'],['italien','terrasse'],true),
  _p('p26','Kodawari Ramen','restaurant',48.8530,2.3360,'29 Rue Mazarine, 75006 Paris',4.4,4100,2,['décontracté','animé','insolite'],['pop'],['japonais']),
  _p('p27','Sushi B','restaurant',48.8676,2.3360,'5 Rue Rameau, 75002 Paris',4.7,560,4,['chic','intimiste'],['lounge'],['japonais','gastronomique'],true),
  _p('p28','Liza','restaurant',48.8676,2.3399,'14 Rue de la Banque, 75002 Paris',4.4,2300,3,['cosy','romantique'],['lounge','latino'],['libanais']),
  _p('p29','Desi Road','restaurant',48.8543,2.3330,'14 Rue Dauphine, 75006 Paris',4.3,1900,2,['cosy','familial'],['latino'],['indien']),
  _p('p30','Lao Siam','restaurant',48.8722,2.3826,'49 Rue de Belleville, 75019 Paris',4.4,3600,2,['décontracté','familial','animé'],['pop'],['thai']),
  _p('p31','Pho 14','restaurant',48.8270,2.3590,'129 Avenue de Choisy, 75013 Paris',4.3,5400,1,['décontracté','familial'],['pop'],['vietnamien']),
  _p('p32','Le Coq Rico','restaurant',48.8867,2.3409,'98 Rue Lepic, 75018 Paris',4.3,1800,4,['chic','familial'],['jazz'],['gastronomique','terrasse']),
  _p('p33','Big Fernand','restaurant',48.8730,2.3470,'55 Rue du Faubourg Poissonniere, 75009 Paris',4.3,6700,2,['décontracté','animé','familial'],['rock','pop'],['burger']),
  _p('p34','PNY Paris New York','restaurant',48.8702,2.3548,'50 Rue du Faubourg Saint-Denis, 75010 Paris',4.4,8200,2,['branché','décontracté'],['funk','soul'],['burger']),
  _p('p35','Wild & The Moon','restaurant',48.8616,2.3662,'55 Rue Charlot, 75003 Paris',4.2,2100,2,['décontracté','branché'],['lounge'],['vegan','brunch']),
  _p('p36','Le Potager du Marais','restaurant',48.8617,2.3565,'24 Rue Rambuteau, 75003 Paris',4.3,1600,2,['cosy','intimiste'],['jazz'],['vegan']),
  _p('p37','Breizh Cafe','restaurant',48.8593,2.3637,'109 Rue Vieille du Temple, 75003 Paris',4.4,9100,2,['cosy','familial'],['pop'],['crêperie']),
  _p('p38','Hero','restaurant',48.8662,2.3470,'289 Rue Saint-Denis, 75002 Paris',4.3,2700,2,['animé','branché'],['funk','soul'],['coréen','cocktails']),
  _p('p39','Anahuacalli','restaurant',48.8487,2.3501,'30 Rue des Bernardins, 75005 Paris',4.4,1400,3,['cosy','familial','romantique'],['latino'],['mexicain']),
  _p('p40','La Coupole','restaurant',48.8419,2.3290,'102 Boulevard du Montparnasse, 75014 Paris',4.2,12800,3,['business','festif','chic'],['jazz'],['brasserie','terrasse']),
  _p('p41','Le Tout-Paris','restaurant',48.8585,2.3470,'Cheval Blanc 8 Quai du Louvre, 75001 Paris',4.5,880,4,['chic','romantique'],['lounge'],['gastronomique','rooftop','vue Tour Eiffel'],true),
  _p('p42','Bouillon Republique','restaurant',48.8674,2.3636,'39 Boulevard du Temple, 75003 Paris',4.3,8900,1,['festif','familial','décontracté'],['pop'],['bistrot']),
  // ===================== HOTELS =====================
  _p('p43','Hotel Costes','hotel',48.8676,2.3274,'239 Rue Saint-Honore, 75001 Paris',4.4,1800,4,['chic','festif'],['lounge','house'],['palace','terrasse'],true),
  _p('p44','Le Pavillon de la Reine','hotel',48.8556,2.3661,'28 Place des Vosges, 75003 Paris',4.7,950,4,['romantique','chic','intimiste'],['lounge'],['boutique-hôtel','jardin']),
  _p('p45','Hotel Grand Amour','hotel',48.8714,2.3550,'18 Rue de la Fidelite, 75010 Paris',4.3,1100,3,['cosy','festif','branché'],['pop','afro'],['boutique-hôtel','design','terrasse']),
  _p('p46','Generator Paris','hotel',48.8809,2.3700,'9-11 Place du Colonel Fabien, 75010 Paris',4.1,6400,2,['festif','décontracté','business'],['house','pop'],['rooftop','vue Tour Eiffel']),
  _p('p47','Mama Shelter Paris East','hotel',48.8676,2.4053,'109 Rue de Bagnolet, 75020 Paris',4.2,3900,2,['festif','décontracté','familial'],['afro','house'],['rooftop','design']),
  _p('p48','Le Bristol Paris','hotel',48.8721,2.3157,'112 Rue du Faubourg Saint-Honore, 75008 Paris',4.8,2600,4,['chic','romantique','business'],['lounge'],['palace','jardin'],true),
  _p('p49','Hotel Particulier Montmartre','hotel',48.8876,2.3380,'23 Avenue Junot, 75018 Paris',4.5,720,4,['romantique','intimiste','insolite'],['jazz','lounge'],['boutique-hôtel','jardin'],true),
  _p('p50','CitizenM Paris Gare de Lyon','hotel',48.8443,2.3743,'17 Boulevard Diderot, 75012 Paris',4.4,4800,2,['décontracté','business','branché'],['house'],['design','rooftop']),
  _p('p51','Hotel Providence','hotel',48.8709,2.3555,'90 Rue Rene Boulanger, 75010 Paris',4.4,1300,3,['cosy','romantique','intimiste'],['jazz'],['boutique-hôtel','cocktails']),
  _p('p52','OFF Paris Seine','hotel',48.8388,2.3736,'20-22 Port Austerlitz, 75013 Paris',4.2,2200,3,['insolite','branché','romantique'],['lounge','house'],['péniche','design','terrasse']),
  _p('p53','Hotel Molitor','hotel',48.8447,2.2530,'13 Rue Nungesser et Coli, 75016 Paris',4.4,3400,4,['branché','festif','familial'],['house','pop'],['design','rooftop'],true),
  _p('p54','Mob Hotel Les Puces','hotel',48.9018,2.3447,'4-6 Rue Gambetta, 93400 Saint-Ouen',4.2,2900,2,['décontracté','familial','branché'],['afro','funk'],['rooftop','terrasse','design']),
  // ===================== BARS / ROOFTOPS (suite) =====================
  _p('p55','Le Perchoir Menilmontant','bar',48.8668,2.3897,'14 Rue Crespin du Gast, 75011 Paris',4.3,6100,3,['festif','branché'],['house','lounge'],['rooftop','terrasse','cocktails','vue Tour Eiffel']),
  _p('p56','Le Tres Particulier','bar',48.8884,2.3375,'23 Avenue Junot, 75018 Paris',4.4,2400,4,['intimiste','romantique','insolite'],['jazz','lounge'],['speakeasy','jardin','cocktails'],true),
  _p('p57','Moonshiner','bar',48.8554,2.3739,'5 Rue Sedaine, 75011 Paris',4.5,1700,2,['intimiste','branché'],['jazz','soul'],['speakeasy','cocktails']),
  _p('p58','Lavomatic','bar',48.8675,2.3656,'30 Rue Rene Boulanger, 75010 Paris',4.3,2900,2,['branché','insolite','animé'],['funk','house'],['speakeasy','cocktails']),
  _p('p59','Dirty Dick','bar',48.8817,2.3372,'10 Rue Frochot, 75009 Paris',4.4,2100,2,['festif','animé','insolite'],['latino','pop'],['cocktails']),
  _p('p60','Combat','bar',48.8721,2.3847,'63 Rue de Belleville, 75019 Paris',4.5,1500,2,['cosy','branché'],['soul','funk'],['cocktails','vins nature']),
  _p('p61','Bar Botaniste Shangri-La','bar',48.8639,2.2898,'10 Avenue d Iena, 75116 Paris',4.6,640,4,['chic','romantique','business'],['lounge','jazz'],['cocktails'],true),
  _p('p62','Le Mary Celeste','bar',48.8624,2.3631,'1 Rue Commines, 75003 Paris',4.3,1300,3,['branché','cosy'],['lounge','soul'],['cocktails','fruits de mer']),
  // ===================== RESTAURANTS (suite) =====================
  _p('p63','Le Chateaubriand','restaurant',48.8669,2.3717,'129 Avenue Parmentier, 75011 Paris',4.4,2600,4,['chic','branché'],['lounge'],['gastronomique'],true),
  _p('p64','Frenchie','restaurant',48.8662,2.3486,'5 Rue du Nil, 75002 Paris',4.5,3300,4,['chic','romantique','branché'],['lounge'],['gastronomique','bistrot'],true),
  _p('p65','Bistrot Paul Bert','restaurant',48.8527,2.3849,'18 Rue Paul Bert, 75011 Paris',4.4,4200,3,['cosy','romantique'],['jazz'],['bistrot','terrasse']),
  _p('p66','Chez Janou','restaurant',48.8564,2.3671,'2 Rue Roger Verlomme, 75003 Paris',4.4,7800,2,['festif','cosy','familial'],['lounge'],['bistrot','terrasse']),
  _p('p67','L\'As du Fallafel','restaurant',48.8576,2.3593,'34 Rue des Rosiers, 75004 Paris',4.4,16200,1,['décontracté','animé','familial'],['pop'],['libanais']),
  _p('p68','Miznon','restaurant',48.8580,2.3590,'22 Rue des Ecouffes, 75004 Paris',4.4,5900,2,['animé','décontracté'],['pop','latino'],['libanais','vegan']),
  _p('p69','Ober Mamma','restaurant',48.8615,2.3739,'107 Boulevard Richard-Lenoir, 75011 Paris',4.4,12100,2,['animé','festif','familial'],['pop'],['italien','pizza']),
  _p('p70','Blueberry Maki Bar','restaurant',48.8518,2.3360,'6 Rue du Sabot, 75006 Paris',4.5,1100,3,['cosy','branché'],['lounge'],['japonais']),
  _p('p71','Dumbo','restaurant',48.8666,2.3679,'20 Rue Rambuteau, 75003 Paris',4.5,4600,2,['décontracté','animé','branché'],['funk','soul'],['burger']),
  _p('p72','Chez l\'Ami Jean','restaurant',48.8588,2.3050,'27 Rue Malar, 75007 Paris',4.5,2200,3,['cosy','animé'],['jazz'],['bistrot','gastronomique']),
  _p('p73','Angelina','restaurant',48.8654,2.3284,'226 Rue de Rivoli, 75001 Paris',4.4,18900,3,['chic','romantique','familial'],['lounge'],['brunch','terrasse']),
  _p('p74','Le Servan','restaurant',48.8636,2.3809,'32 Rue Saint-Maur, 75011 Paris',4.4,1500,3,['cosy','branché','romantique'],['jazz'],['gastronomique','bistrot']),
  // ===================== HOTELS (suite) =====================
  _p('p75','Ritz Paris','hotel',48.8681,2.3284,'15 Place Vendome, 75001 Paris',4.8,3600,4,['chic','romantique','business'],['lounge'],['palace','jardin'],true),
  _p('p76','Four Seasons George V','hotel',48.8686,2.3008,'31 Avenue George V, 75008 Paris',4.8,4100,4,['chic','romantique','business'],['lounge'],['palace'],true),
  _p('p77','Le Meurice','hotel',48.8654,2.3281,'228 Rue de Rivoli, 75001 Paris',4.7,2900,4,['chic','business'],['lounge'],['palace'],true),
  _p('p78','The Hoxton Paris','hotel',48.8688,2.3506,'30-32 Rue du Sentier, 75002 Paris',4.4,3200,3,['branché','cosy','business'],['house','soul'],['boutique-hôtel','design']),
  _p('p79','SO/ Paris','hotel',48.8520,2.3610,'10 Rue Agrippa d Aubigne, 75004 Paris',4.5,1800,4,['branché','festif','chic'],['house','lounge'],['rooftop','design','vue Tour Eiffel'],true),
  _p('p80','Brach Paris','hotel',48.8636,2.2820,'1-7 Rue Jean Richepin, 75116 Paris',4.6,1400,4,['branché','chic','cosy'],['lounge','soul'],['design','rooftop'],true),
  _p('p81','Hotel Rochechouart','hotel',48.8820,2.3437,'55 Boulevard de Rochechouart, 75009 Paris',4.4,2100,3,['festif','branché','décontracté'],['house','pop'],['rooftop','design','terrasse']),
  _p('p82','Kimpton St Honore','hotel',48.8712,2.3349,'27-29 Boulevard des Capucines, 75002 Paris',4.5,1600,4,['branché','chic','festif'],['house','lounge'],['rooftop','design','vue Tour Eiffel'],true),
  _p('p83','25hours Hotel Terminus Nord','hotel',48.8810,2.3573,'12 Boulevard de Denain, 75010 Paris',4.3,2400,2,['branché','décontracté','familial'],['funk','afro'],['design','boutique-hôtel']),
  _p('p84','Hotel National des Arts et Metiers','hotel',48.8659,2.3560,'243 Rue Saint-Martin, 75003 Paris',4.4,1900,3,['branché','romantique','cosy'],['lounge','house'],['rooftop','design','boutique-hôtel']),
  // ===================== RESTAURANTS (suite 2) =====================
  _p('p85','Septime (2e adresse)','restaurant',48.8540,2.3785,'80 Rue de Charonne, 75011 Paris',4.7,3200,3,['chic','intimiste','romantique'],['jazz','soul'],['gastronomique','vins nature'],true),
  _p('p86','Frenchie Bar a Vins','restaurant',48.8639,2.3473,'5 Rue du Nil, 75002 Paris',4.6,2800,3,['chic','branché','intimiste'],['jazz','soul'],['gastronomique','brunch'],true),
  _p('p87','Le Comptoir du Relais','restaurant',48.8531,2.3355,'9 Carrefour de l\'Odeon, 75006 Paris',4.4,4200,2,['animé','décontracté','romantique'],['jazz','lounge'],['bistrot','terrasse']),
  _p('p88','Cafe de Flore','restaurant',48.8539,2.3330,'172 Boulevard Saint-Germain, 75006 Paris',4.1,12000,3,['chic','animé','romantique'],['jazz','lounge'],['brasserie','terrasse']),
  _p('p89','Holybelly','restaurant',48.8674,2.3612,'19 Rue Lucien Sampaix, 75010 Paris',4.5,5600,2,['décontracté','branché','familial'],['pop','soul'],['brunch','vegan']),
  _p('p90','Bouillon Pigalle Clichy','restaurant',48.8824,2.3482,'22 Boulevard de Clichy, 75018 Paris',4.3,8900,1,['animé','familial','décontracté'],['pop','funk'],['brasserie']),
  _p('p91','Mokonuts','restaurant',48.8554,2.3784,'5 Rue Saint-Bernard, 75011 Paris',4.6,1800,2,['cosy','décontracté','intimiste'],['soul','pop'],['brunch','vegan']),
  _p('p92','Chez L\'Ami Jean','restaurant',48.8596,2.3078,'27 Rue Malar, 75007 Paris',4.5,3100,2,['animé','décontracté','familial'],['jazz'],['bistrot','gastronomique']),
  _p('p93','Le Baratin','restaurant',48.8677,2.3965,'3 Rue Jouye-Rouve, 75020 Paris',4.4,1400,2,['intimiste','décontracté','branché'],['jazz','soul'],['bistrot','vins nature']),
  _p('p94','Tomy & Co','restaurant',48.8571,2.3071,'22 Rue Surcouf, 75007 Paris',4.6,1200,3,['chic','intimiste','romantique'],['jazz','lounge'],['gastronomique'],true),
  _p('p95','Clown Bar','restaurant',48.8622,2.3741,'114 Rue Amelot, 75011 Paris',4.5,2200,2,['branché','animé','insolite'],['jazz','afro'],['bistrot','vins nature']),
  _p('p96','Le Servan','restaurant',48.8584,2.3826,'32 Rue Saint-Maur, 75011 Paris',4.4,2600,2,['branché','cosy','animé'],['afro','soul'],['gastronomique','vietnamien','thai']),
  _p('p97','Bouillon Chartier','restaurant',48.8726,2.3443,'7 Rue du Faubourg Montmartre, 75009 Paris',4.1,22000,1,['animé','familial','insolite'],['jazz'],['brasserie']),
  _p('p98','Pink Mamma Rooftop','restaurant',48.8822,2.3435,'20ter Rue de Douai, 75009 Paris',4.4,7800,2,['branché','festif','romantique'],['pop','afro'],['italien','rooftop','terrasse'],true),
  _p('p99','East Mamma Faubourg','restaurant',48.8531,2.3766,'133 Rue du Faubourg Saint-Antoine, 75011 Paris',4.3,9200,2,['animé','festif','branché'],['pop','afro'],['italien','pizza']),
  _p('p100','Cafe de la Paix','restaurant',48.8712,2.3319,'5 Place de l\'Opera, 75009 Paris',4.3,6500,3,['chic','romantique','business'],['jazz','lounge'],['brasserie','gastronomique','terrasse']),
  _p('p101','Sushi Yoshinori','restaurant',48.8527,2.3312,'18 Rue Gregoire de Tours, 75006 Paris',4.7,900,3,['chic','intimiste','romantique'],['lounge'],['japonais','gastronomique'],true),
  _p('p102','Les Enfants Rouges','restaurant',48.8625,2.3607,'39 Rue de Bretagne, 75003 Paris',4.2,8300,2,['animé','familial','décontracté'],['pop','afro'],['brunch','marché']),
  _p('p103','Le Grand Bain','restaurant',48.8732,2.3850,'14 Rue Denoyez, 75020 Paris',4.5,1600,2,['branché','décontracté','animé'],['afro','funk'],['vegan','gastronomique','vins nature']),
  _p('p104','Yard','restaurant',48.8609,2.3742,'6 Rue de Mont-Louis, 75011 Paris',4.3,1900,2,['branché','décontracté','cosy'],['soul','pop'],['brunch','vins nature','cocktails']),
  // ===================== BARS (suite 3) =====================
  _p('p105','Little Red Door Charlot','bar',48.8598,2.3566,'60 Rue Charlot, 75003 Paris',4.5,2400,3,['chic','intimiste','branché'],['house','lounge'],['cocktails','speakeasy'],true),
  _p('p106','Mary Celeste Cocktails','bar',48.8597,2.3568,'1 Rue Commines, 75003 Paris',4.4,3100,2,['animé','branché','décontracté'],['afro','soul'],['cocktails','fruits de mer']),
  _p('p107','ECC Monnaie','bar',48.8619,2.3441,'60 Rue de la Monnaie, 75001 Paris',4.5,4200,3,['chic','intimiste','branché'],['house','lounge'],['cocktails','speakeasy'],true),
  _p('p108','Glass','bar',48.8809,2.3414,'7 Rue Frochot, 75009 Paris',4.1,1800,2,['festif','branché','animé'],['rock','pop'],['cocktails','club']),
  _p('p109','Lulu White','bar',48.8809,2.3409,'12 Rue Frochot, 75009 Paris',4.4,2100,2,['insolite','intimiste','branché'],['jazz','lounge'],['cocktails','speakeasy']),
  _p('p110','La Cave a Michel','bar',48.8748,2.3618,'36 Rue Sainte-Marthe, 75010 Paris',4.5,1600,2,['décontracté','cosy','animé'],['jazz','afro'],['vins nature','terrasse']),
  _p('p111','Sherry Butt','bar',48.8538,2.3607,'20 Rue Beautreillis, 75004 Paris',4.4,2800,2,['cosy','branché','intimiste'],['jazz','soul'],['cocktails']),
  _p('p112','Le Syndicat 10e','bar',48.8724,2.3580,'51 Rue du Faubourg Saint-Denis, 75010 Paris',4.5,2500,2,['branché','animé','insolite'],['house','techno'],['cocktails','speakeasy'],true),
  _p('p113','Danico','bar',48.8645,2.3456,'6 Rue Vivienne, 75002 Paris',4.5,1900,3,['chic','intimiste','branché'],['house','lounge'],['cocktails','speakeasy']),
  _p('p114','Au Sauvignon','bar',48.8560,2.3320,'80 Rue des Saints-Peres, 75007 Paris',4.2,3400,2,['cosy','décontracté','intimiste'],['jazz'],['vins nature','terrasse']),
  _p('p115','Brasserie Barbes','bar',48.8827,2.3482,'2 Boulevard Barbes, 75018 Paris',4.0,5200,2,['animé','décontracté','festif'],['afro','pop'],['terrasse','bière artisanale']),
  _p('p116','Ballroom du Beef Club','bar',48.8624,2.3477,'58 Rue Jean-Jacques Rousseau, 75001 Paris',4.3,2600,3,['festif','branché','insolite'],['house','techno'],['cocktails','speakeasy','club']),
  _p('p117','Gravity Bar','bar',48.8751,2.3578,'44 Rue des Vinaigriers, 75010 Paris',4.3,1400,2,['décontracté','branché','animé'],['funk','soul'],['bière artisanale']),
  // ===================== HOTELS (suite 3) =====================
  _p('p118','Le Grand Mazarin','hotel',48.8577,2.3545,'6 Rue des Archives, 75004 Paris',4.5,1800,3,['chic','romantique','cosy'],['lounge','jazz'],['boutique-hôtel','design']),
  _p('p119','Hotel du Petit Moulin','hotel',48.8605,2.3596,'29 Rue du Poitou, 75003 Paris',4.4,2100,3,['branché','romantique','insolite'],['lounge'],['boutique-hôtel','design'],true),
  _p('p120','Mama Shelter East','hotel',48.8699,2.4038,'109 Rue de Bagnolet, 75020 Paris',4.2,3800,2,['festif','branché','décontracté'],['house','pop','afro'],['design','rooftop']),
  _p('p121','Hotel de Nell','hotel',48.8756,2.3463,'7-9 Rue du Conservatoire, 75009 Paris',4.5,1600,3,['cosy','romantique','chic'],['jazz','lounge'],['boutique-hôtel','design']),
  _p('p122','Hotel des Grands Boulevards','hotel',48.8703,2.3481,'17 Boulevard Poissonniere, 75002 Paris',4.5,4200,3,['branché','chic','romantique'],['house','lounge'],['boutique-hôtel','jardin','terrasse'],true),
  _p('p123','Off Paris Seine','hotel',48.8383,2.3670,'Port de la Gare, 75013 Paris',4.3,2200,3,['insolite','romantique','décontracté'],['lounge','afro'],['péniche','design']),
  _p('p124','Hotel Drouot','hotel',48.8756,2.3422,'6 Rue Drouot, 75009 Paris',4.3,1400,2,['cosy','branché','décontracté'],['lounge'],['boutique-hôtel','design']),
  _p('p125','Hotel La Louisiane','hotel',48.8538,2.3355,'60 Rue de Seine, 75006 Paris',4.1,2800,2,['cosy','romantique','décontracté'],['jazz'],['bistrot','boutique-hôtel']),
  // ===================== ROOFTOPS =====================
  _p('p126','Le Perchoir Menilmontant Rooftop','rooftop',48.8647,2.3882,'14 Rue Crespin du Gast, 75011 Paris',4.5,8400,2,['branché','festif','animé'],['house','afro'],['rooftop','cocktails','vue panoramique'],true),
  _p('p127','Le Perchoir Marais Rooftop','rooftop',48.8572,2.3519,'33 Rue de la Verrerie, 75004 Paris',4.4,6200,2,['branché','animé','festif'],['house','lounge'],['rooftop','cocktails','vue panoramique'],true),
  _p('p128','Galeries Lafayette Rooftop','rooftop',48.8741,2.3319,'40 Boulevard Haussmann, 75009 Paris',4.4,25000,1,['animé','familial','décontracté'],[],['rooftop','vue panoramique','vue Tour Eiffel','gratuit']),
  _p('p129','Terrass Hotel Rooftop','rooftop',48.8847,2.3316,'12 Rue Joseph de Maistre, 75018 Paris',4.5,3200,2,['chic','romantique','branché'],['lounge','house'],['rooftop','vue panoramique','cocktails','terrasse'],true),
  _p('p130','Maison Blanche','rooftop',48.8735,2.3025,'15 Avenue Montaigne, 75008 Paris',4.3,1800,3,['chic','romantique','business'],['lounge','house'],['rooftop','vue panoramique','gastronomique']),
  _p('p131','L\'Oiseau Blanc Peninsula','rooftop',48.8686,2.2964,'19 Avenue Kleber, 75016 Paris',4.7,2400,4,['chic','romantique','business'],['lounge'],['rooftop','vue Tour Eiffel','gastronomique','palace'],true),
  _p('p132','Ciel de Paris Tour Montparnasse','rooftop',48.8419,2.3219,'33 Avenue du Maine, 75015 Paris',4.2,9600,3,['chic','romantique','animé'],['lounge'],['rooftop','vue panoramique','gastronomique']),
  _p('p133','Rooftop du Printemps Haussmann','rooftop',48.8738,2.3316,'64 Boulevard Haussmann, 75009 Paris',4.3,18000,1,['animé','décontracté','familial'],[],['rooftop','vue panoramique','vue Tour Eiffel','gratuit']),
  _p('p134','La Samaritaine Rooftop','rooftop',48.8607,2.3452,'9 Rue de la Monnaie, 75001 Paris',4.4,2100,3,['chic','branché','romantique'],['lounge','house'],['rooftop','vue panoramique','cocktails'],true),
  // ===================== PARCS =====================
  _p('p135','Jardin du Luxembourg','parc',48.8462,2.3372,'Rue de Medicis, 75006 Paris',4.8,45000,1,['calme','romantique','familial'],[],['jardin','pelouse','pique-nique','gratuit']),
  _p('p136','Parc des Buttes-Chaumont','parc',48.8798,2.3816,'1 Rue Botzaris, 75019 Paris',4.7,38000,1,['calme','romantique','familial'],[],['nature','pelouse','pique-nique','vue panoramique','gratuit'],true),
  _p('p137','Jardin des Tuileries','parc',48.8638,2.3274,'Place de la Concorde, 75001 Paris',4.5,52000,1,['animé','romantique','familial'],[],['jardin','pelouse','pique-nique','vue Tour Eiffel','gratuit']),
  _p('p138','Parc de Belleville','parc',48.8690,2.3877,'47 Rue des Couronnes, 75020 Paris',4.5,12000,1,['décontracté','familial','animé'],[],['vue panoramique','pelouse','pique-nique','gratuit']),
  _p('p139','Promenade Plantee','parc',48.8476,2.3712,'1 Coulee Verte Rene-Dumont, 75012 Paris',4.5,8500,1,['calme','romantique','insolite'],[],['nature','jardin','pique-nique','gratuit','instagrammable']),
  _p('p140','Parc Monceau','parc',48.8797,2.3096,'35 Boulevard de Courcelles, 75008 Paris',4.6,22000,1,['calme','chic','romantique'],[],['jardin','pelouse','pique-nique','gratuit']),
  _p('p141','Jardin des Plantes','parc',48.8447,2.3598,'57 Rue Cuvier, 75005 Paris',4.4,18000,2,['calme','familial','décontracté'],[],['nature','jardin','pique-nique']),
  _p('p142','Parc de la Villette','parc',48.8940,2.3933,'211 Avenue Jean Jaures, 75019 Paris',4.5,35000,1,['animé','familial','décontracté'],[],['nature','pelouse','pique-nique','gratuit']),
  _p('p143','Square des Batignolles','parc',48.8863,2.3189,'Rue Cardinet, 75017 Paris',4.3,4500,1,['calme','familial','décontracté'],[],['nature','pelouse','pique-nique','gratuit']),
  _p('p144','Bois de Vincennes','parc',48.8344,2.4339,'Route de la Pyramide, 75012 Paris',4.5,28000,1,['calme','familial','décontracté'],[],['nature','pelouse','pique-nique','gratuit']),
  // ===================== ADRESSES & SPOTS PHOTO =====================
  _p('p145','Rue de Cremieux','adresse',48.8474,2.3688,'Rue de Cremieux, 75012 Paris',4.6,15000,1,['insolite','romantique','animé'],[],['instagrammable','gratuit']),
  _p('p146','Rue Montorgueil','adresse',48.8633,2.3474,'Rue Montorgueil, 75002 Paris',4.5,35000,1,['animé','familial','décontracté'],[],['marché','gratuit','instagrammable']),
  _p('p147','Passage des Panoramas','adresse',48.8706,2.3447,'11 Boulevard Montmartre, 75002 Paris',4.5,12000,1,['insolite','romantique','cosy'],[],['galerie couverte','instagrammable','gratuit']),
  _p('p148','Rue Denoyez','adresse',48.8732,2.3850,'Rue Denoyez, 75020 Paris',4.3,8000,1,['insolite','branché','décontracté'],[],['street art','instagrammable','gratuit']),
  _p('p149','Passage Jouffroy','adresse',48.8727,2.3461,'10 Boulevard Montmartre, 75009 Paris',4.5,8500,1,['insolite','cosy','romantique'],[],['galerie couverte','instagrammable','gratuit']),
  _p('p150','Marche d\'Aligre','adresse',48.8497,2.3740,'Place d\'Aligre, 75012 Paris',4.6,18000,1,['animé','familial','décontracté'],[],['marché','gratuit']),
  _p('p151','Rue des Martyrs','adresse',48.8793,2.3404,'Rue des Martyrs, 75009 Paris',4.4,22000,1,['animé','décontracté','familial'],[],['marché','gastronomique','gratuit']),
  _p('p152','Galerie Vivienne','adresse',48.8648,2.3381,'4 Rue des Petits Champs, 75002 Paris',4.6,10000,1,['chic','romantique','insolite'],[],['galerie couverte','instagrammable','gratuit']),
  _p('p153','Canal Saint-Martin','adresse',48.8720,2.3635,'Quai de Valmy, 75010 Paris',4.6,32000,1,['romantique','décontracté','animé'],[],['instagrammable','pique-nique','gratuit']),
];

Map<String, dynamic> _p(
  String id,
  String name,
  String type,
  double lat,
  double lon,
  String address,
  double rating,
  int reviewCount,
  int priceLevel,
  List<String> ambianceTags,
  List<String> musicTags,
  List<String> styleTags, [
  bool isPremium = false,
  String? websiteUrl,
]) =>
    {
      'id': id,
      'name': name,
      'type': type,
      'latitude': lat,
      'longitude': lon,
      'address': address,
      'rating': rating,
      'review_count': reviewCount,
      'price_level': priceLevel,
      'ambiance_tags': ambianceTags,
      'music_tags': musicTags,
      'style_tags': styleTags,
      'is_premium': isPremium,
      'website_url': ?websiteUrl,
    };
