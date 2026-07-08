#!/bin/sh
# Version: 11 (extraction + fusion automatique des .po + compilation)

DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

# On extrait l'ID proprement depuis metadata.json
plasmoidName=$(grep '"Id"' "$DIR/../metadata.json" | cut -d'"' -f4)

if [ -z "$plasmoidName" ]; then
    echo "[build] Erreur: Impossible de lire l'ID dans metadata.json."
    exit 1
fi

# LE VOICI : KDE exige que le fichier .mo commence par "plasma_applet_"
projectName="plasma_applet_${plasmoidName}"

# Optionnel : évite l'avertissement xgettext sur --msgid-bugs-address
website=$(grep '"Website"' "$DIR/../metadata.json" | cut -d'"' -f4)

for tool in msgfmt msgmerge xgettext msguniq; do
    if [ -z "$(which $tool)" ]; then
        echo "[build] Erreur: $tool introuvable."
        exit 1
    fi
done

# --- 1. Extraction : génère un template.pot propre depuis les sources QML/JS ---

potFile="$DIR/template.pot"

echo "[build] Extraction des chaînes traduisibles..."

# On se place dans translate/ pour que les commentaires "#:" du .pot
# contiennent des chemins relatifs (../contents/...) et non absolus.
cd "$DIR" || exit 1
sourceFiles=`find ../contents \( -name '*.qml' -o -name '*.js' \) | sort`

if [ -z "$sourceFiles" ]; then
    echo "[build] Erreur: Aucun fichier .qml/.js trouvé dans contents/."
    exit 1
fi

xgettext \
    --from-code=UTF-8 \
    --language=JavaScript \
    --keyword=i18n:1 \
    --keyword=i18nc:1c,2 \
    --keyword=i18np:1,2 \
    --keyword=i18ncp:1c,2,3 \
    --keyword=i18nd:2 \
    --keyword=i18ndc:2c,3 \
    --package-name="$projectName" \
    --msgid-bugs-address="${website}" \
    --add-comments=TRANSLATORS: \
    --no-wrap \
    -o "$potFile" \
    $sourceFiles

if [ $? -ne 0 ]; then
    echo "[build] Erreur: échec de l'extraction avec xgettext."
    exit 1
fi

# Tri stable du .pot (remplace l'ancien --sort-output, devenu obsolète)
msguniq --sort-output --no-wrap --output-file="$potFile" "$potFile"

echo " -> Généré : translate/template.pot"

# --- 2. Fusion automatique : met à jour chaque .po avec les nouvelles chaînes ---

echo "[build] Mise à jour des traductions (.po) depuis le template..."
poFiles=`find "$DIR" -maxdepth 1 -name '*.po' | sort`

if [ -z "$poFiles" ]; then
    echo "[build] Avertissement: aucun fichier .po trouvé, rien à fusionner."
else
    for po in $poFiles; do
        msgmerge --update --backup=off --quiet "$po" "$potFile"
        echo " -> Mis à jour : $(basename "$po")"
    done
fi

# --- 3. Compilation : .po -> .mo pour chaque langue ---

echo "[build] Nettoyage des anciens fichiers de traduction..."
rm -rf "$DIR/../contents/locale"/*/LC_MESSAGES/*.mo

echo "[build] Compilation pour le domaine : $projectName"

for po in $poFiles; do
    catLocale=`basename ${po%.*}`
    installPath="$DIR/../contents/locale/${catLocale}/LC_MESSAGES/${projectName}.mo"

    mkdir -p "$(dirname "$installPath")"
    msgfmt -o "${installPath}" "$po"
    echo " -> Généré : $installPath"
done

echo "[build] Terminé avec succès."
