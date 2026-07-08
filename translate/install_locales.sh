#!/bin/bash

APP_DOMAIN="plasma_applet_com.github.samy879.minimalist-animated-weather"
LOCALE_DIR="../contents/locale"
USER_LOCALE_DIR="$HOME/.local/share/locale"
# Utilisation du dossier courant au lieu de la racine utilisateur
TEST_LOCALE_DIR="$PWD/.locale"
TARGET_LANG=$1

if [ -z "$TARGET_LANG" ]; then
    echo "❌ Erreur : Tu dois spécifier une langue. Exemple : ./install_locales.sh ru"
    exit 1
fi

# 1. Compilation
echo "==> 1. Compilation des fichiers .po..."
sh build.sh

# 2. Copie temporaire
echo -e "\n==> 2. Installation temporaire des fichiers .mo dans $USER_LOCALE_DIR..."
for lang_dir in "$LOCALE_DIR"/*; do
    if [ -d "$lang_dir" ]; then
        lang=$(basename "$lang_dir")
        mkdir -p "$USER_LOCALE_DIR/$lang/LC_MESSAGES"
        if [ -f "$lang_dir/LC_MESSAGES/$APP_DOMAIN.mo" ]; then
            cp "$lang_dir/LC_MESSAGES/$APP_DOMAIN.mo" "$USER_LOCALE_DIR/$lang/LC_MESSAGES/"
            echo " ✔️  $lang copié"
        fi
    fi
done

# 3. Génération ciblée (uniquement la langue demandée)
echo -e "\n==> 3. Génération de la locale de test dans $TEST_LOCALE_DIR..."
mkdir -p "$TEST_LOCALE_DIR"

declare -A locales=(
    ["ar"]="ar_EG"
    ["de"]="de_DE"
    ["es"]="es_ES"
    ["fr"]="fr_FR"
    ["it"]="it_IT"
    ["ja"]="ja_JP"
    ["nl"]="nl_NL"
    ["pt"]="pt_PT"
    ["ru"]="ru_RU"
    ["tr"]="tr_TR"
    ["vi"]="vi_VN"
    ["zh_cn"]="zh_CN"
)

if [ -n "${locales[$TARGET_LANG]}" ]; then
    full_locale="${locales[$TARGET_LANG]}.UTF-8"
    echo " ⏳ Génération de $full_locale..."
    localedef -f UTF-8 -i ${locales[$TARGET_LANG]} "$TEST_LOCALE_DIR/$full_locale" >/dev/null 2>&1
else
    echo "⚠️ Langue '$TARGET_LANG' non répertoriée dans le script. Le rendu risque d'être en anglais."
fi

# 4. Lancement du test (le script se met en pause tant que la fenêtre est ouverte)
echo -e "\n🚀 Lancement du test pour la langue : $TARGET_LANG..."
LOCPATH="$TEST_LOCALE_DIR" ./plasmoidlocaletest.sh "$TARGET_LANG"

# 5. Nettoyage absolu (s'exécute dès que tu fermes le widget)
echo -e "\n🧹 Fermeture détectée. Nettoyage des fichiers temporaires..."
rm -rf "$TEST_LOCALE_DIR"
rm -f "$USER_LOCALE_DIR"/*/LC_MESSAGES/$APP_DOMAIN.mo
echo "✅ Système propre. Tout a été effacé avec succès !"
