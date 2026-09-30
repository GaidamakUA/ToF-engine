extends BaseOutcome
class_name MessageOutcome

var text: String
var portrait: Variant = null
var name: String
var side: String = "left"
var colour: Variant = null
var font_size: int = 16
var sound: Variant = null

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var portrait_key: String = "" if self.portrait == null else String(self.portrait)
    var sound_key: String = "" if self.sound == null else String(self.sound)
    var colour_key: String = "" if self.colour == null else String(self.colour)
    self.model.request_presentation(MessagePresentationEvent.new(
        self.text, portrait_key, sound_key, self.name, self.side, colour_key, self.font_size
    ))

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.name = String(details['name'])
    if details.has("portrait"):
        self.portrait = details['portrait']
    if details.has("side"):
        self.side = String(details['side'])
    if details.has("colour"):
        self.colour = details['colour']
    if details.has("font_size"):
        self.font_size = int(details['font_size'])
    if details.has("sound"):
        self.sound = details['sound']
    self.text = String(details['text'])
