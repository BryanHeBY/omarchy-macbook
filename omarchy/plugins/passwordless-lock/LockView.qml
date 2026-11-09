// Lock screen dismissed by a click or any key, retaining background rendering and visual effects.

import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root
  property string backgroundPath: ""
  property string videoPosterPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintUnavailable: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()
  signal dismissRequested()

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  function forcePasswordFocus() {
    if (inputEnabled && !root.activeFocus) root.forceActiveFocus()
  }
  function clearPassword() { passwordTextEdited("") }
  focus: inputEnabled
  onInputEnabledChanged: if (inputEnabled) Qt.callLater(forcePasswordFocus)
  Window.onActiveFocusItemChanged: Qt.callLater(forcePasswordFocus)
  Component.onCompleted: if (inputEnabled) Qt.callLater(forcePasswordFocus)

  Keys.onPressed: function(event) {
    event.accepted = true
    if (root.inputEnabled && !event.isAutoRepeat) root.dismissRequested()
  }
  Keys.onReleased: function(event) { event.accepted = true }

  Rectangle {
    anchors.fill: parent
    color: Commons.Color.background
    BackgroundMedia {
      id: wallpaper
      objectName: "lockWallpaper"
      anchors.fill: parent
      path: root.loadBackground ? (Util.isVideoPath(root.backgroundPath) ? root.videoPosterPath : root.backgroundPath) : ""
      version: root.backgroundVersion
      cached: true
      constrainDecode: true
      decodeSize: Qt.size(width, height)
    }
    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }
    Text {
      anchors.centerIn: parent
      width: Math.max(0, parent.width - 48)
      text: strings.t("dismissHint")
      textFormat: Text.PlainText
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      color: Commons.Color.lock.text
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
    }
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      hoverEnabled: true
      onClicked: if (root.inputEnabled) root.dismissRequested()
      onPositionChanged: root.wakeRequested()
    }
  }
}
