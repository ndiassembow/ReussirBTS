/**
 * 📌 Script d’importation des modules dans Firestore
 * ---------------------------------------------------
 * - Se connecte à Firebase via un serviceAccountKey.json
 * - Permet d’importer des modules, fiches, vidéos et quizzes
 * - Option --reset : supprime les sous-collections avant réimport
 * - Compte et met à jour automatiquement les nombres de fiches, vidéos et quizzes
 */

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

// 🔑 Vérification et chargement de la clé de service
const KEY = "./serviceAccountKey.json";
if (!fs.existsSync(KEY)) {
  console.error("❌ Erreur: serviceAccountKey.json introuvable.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(KEY)),
});
const db = admin.firestore();

/**
 * 🔥 Supprime tous les documents d’une collection Firestore par lots de 500.
 * (utile pour reset les sous-collections avant réimportation)
 */
async function deleteCollection(collectionPath) {
  const colRef = db.collection(collectionPath);
  while (true) {
    const snapshot = await colRef.limit(500).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

/**
 * 🚀 Importer les modules (et leurs sous-données) dans Firestore
 * @param {boolean} reset - si true, supprime d’abord les sous-collections
 */
async function importModules(reset = false) {
  const modulesFile = path.join(__dirname, "modules.json");
  if (!fs.existsSync(modulesFile)) throw new Error("❌ modules.json introuvable");

  // Charger le fichier des modules
  const modules = JSON.parse(fs.readFileSync(modulesFile));

  for (const m of modules) {
    const id = m.id;
    console.log(`\n=== Import du module ${id} ===`);
    const moduleRef = db.collection("modules").doc(id);

    // 1️⃣ Si --reset : on vide les sous-collections
    if (reset) {
      try {
        await deleteCollection(`modules/${id}/fichesSynthese`);
        await deleteCollection(`modules/${id}/videos`);
        await deleteCollection(`modules/${id}/quizzes`);
        console.log("  -> reset des sous-collections réussi ✅");
      } catch (e) {
        console.log("  -> reset partiel ⚠️ :", e.message || e);
      }
    }

    // 2️⃣ Mise à jour du document principal du module
    const moduleDoc = {
      title: m.title || "",
      description: m.description || "",
      countFiches: m.countFiches || 0,
      countVideos: m.countVideos || 0,
      countQuizzes: m.countQuizzes || 0, // sera recalculé
      tags: m.tags || [],
      imageUrl: m.imageUrl || "",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await moduleRef.set(moduleDoc, { merge: true });

    // 3️⃣ Import des fiches
    const fichesFile = path.join(__dirname, `fiches_${id}.json`);
    if (fs.existsSync(fichesFile)) {
      const fiches = JSON.parse(fs.readFileSync(fichesFile));
      for (const f of fiches) {
        await moduleRef.collection("fichesSynthese").doc(f.id).set(f, { merge: true });
      }
      console.log(`  -> fiches importées: ${fiches.length}`);
    } else {
      console.log("  -> pas de fichier fiches (ok)");
    }

    // 4️⃣ Import des vidéos
    const videosFile = path.join(__dirname, `videos_${id}.json`);
    if (fs.existsSync(videosFile)) {
      const videos = JSON.parse(fs.readFileSync(videosFile));
      for (const v of videos) {
        await moduleRef.collection("videos").doc(v.id).set(v, { merge: true });
      }
      console.log(`  -> vidéos importées: ${videos.length}`);
    } else {
      console.log("  -> pas de fichier vidéos (ok)");
    }

    // 5️⃣ Import des quizzes
    const quizzesFile = path.join(__dirname, `quizzes_${id}.json`);
    let quizzesCount = 0;
    if (fs.existsSync(quizzesFile)) {
      const quizzes = JSON.parse(fs.readFileSync(quizzesFile));
      for (const q of quizzes) {
        // Structure normalisée du quiz
        const qDoc = {
          id: q.id,
          moduleId: q.moduleId || id,
          title: q.title || "Quiz",
          description: q.description || "",
          durationSeconds: q.durationSeconds ?? null,
          allowRetake: q.allowRetake ?? true,
          order: q.order ?? 0,
          badgeThresholds: q.badgeThresholds || { gold: 90, silver: 75, bronze: 50 },
          questions: (q.questions || []).map((qq, idx) => ({
            question: (qq.question || "").toString(),
            options: Array.isArray(qq.options) ? qq.options.map(String) : [],
            correctIndex: Number.isInteger(qq.correctIndex)
              ? qq.correctIndex
              : parseInt(qq.correctIndex ?? 0, 10) || 0,
            explanation: (qq.explanation || "").toString(),
          })),
          questionCount: Array.isArray(q.questions) ? q.questions.length : 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await moduleRef.collection("quizzes").doc(q.id).set(qDoc, { merge: true });
        quizzesCount++;
      }
      console.log(`  -> quizzes importés: ${quizzesCount}`);
    } else {
      console.log("  -> pas de fichier quizzes (ok)");
    }

    // 6️⃣ Mise à jour du nombre de quizzes après import
    await moduleRef.set(
      { countQuizzes: quizzesCount, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
  }

  console.log("\n🎉 Import terminé avec succès !");
}

// 🚦 Exécution avec option --reset possible
const doReset = process.argv.includes("--reset");
importModules(doReset).catch((err) => {
  console.error("❌ Erreur import:", err);
  process.exit(1);
});
