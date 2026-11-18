///|
priv struct KsyYamlFrame {
  node : @yaml.Yaml
  anchor : Int32
  mut key : String?
}

///|
priv struct KsyYamlLoader {
  frames : Array[KsyYamlFrame]
  anchors : Map[Int32, @yaml.Yaml]
  documents : Array[@yaml.Yaml]
  mut root : @yaml.Yaml?
  mut error : SchemaError?
}

///|
impl @yaml.MarkedEventReceiver for KsyYamlLoader with fn on_event(
  self,
  event,
  mark,
) {
  if self.error is Some(_) {
    return
  }
  self.receive(event, "YAML line \{mark.line + 1}") catch {
    error => self.error = Some(error)
  }
}

///|
fn KsyYamlLoader::insert(
  self : KsyYamlLoader,
  node : @yaml.Yaml,
  anchor : Int32,
  path : String,
) -> Unit raise SchemaError {
  if anchor > 0 {
    self.anchors[anchor] = node
  }
  if self.frames.last() is Some(frame) {
    match frame.node {
      @yaml.Array(items) => items.push(node)
      @yaml.Map(mapping) =>
        if frame.key is Some(key) {
          guard !mapping.contains(key) else {
            invalid(path, key + ": duplicated key in mapping")
          }
          mapping[key] = node
          frame.key = None
        } else {
          guard node is @yaml.String(key) else {
            invalid(path, "mapping keys must be scalar")
          }
          frame.key = Some(key)
        }
      _ => invalid(path, "unexpected YAML collection")
    }
  } else {
    self.root = Some(node)
  }
}

///|
fn KsyYamlLoader::receive(
  self : KsyYamlLoader,
  event : @yaml.Event,
  path : String,
) -> Unit raise SchemaError {
  match event {
    DocumentStart => self.root = None
    DocumentEnd => self.documents.push(self.root.unwrap_or(@yaml.Null))
    SequenceStart(id~, ..) | MappingStart(id~, ..) => {
      guard self.frames.length() < 128 else {
        invalid(path, "YAML collection depth exceeds 128")
      }
      let node = if event is SequenceStart(_) {
        @yaml.Array([])
      } else {
        @yaml.Map(Map([]))
      }
      self.frames.push({ node, anchor: id, key: None, })
    }
    SequenceEnd | MappingEnd => {
      guard self.frames.pop() is Some(frame) else {
        invalid(path, "unexpected collection end")
      }
      guard frame.key is None else { invalid(path, "mapping key has no value") }
      self.insert(frame.node, frame.anchor, path)
    }
    Scalar(value~, style~, id~, ..) => {
      // Keep scalar key spellings, including numeric switch tags, unchanged.
      let is_key = self.frames.last()
        is Some({ node: @yaml.Map(_), key: None, .. })
      let node = if is_key || !(style is @yaml.Plain) {
        @yaml.String(value)
      } else {
        let parsed = @yaml.Yaml::load_from_string(value[:]) catch {
          _ => invalid(path, "invalid scalar")
        }
        guard parsed is [node] else { invalid(path, "expected one scalar") }
        node
      }
      self.insert(node, id, path)
    }
    Alias(id~) => {
      guard self.anchors.get(id) is Some(node) else {
        invalid(path, "unknown YAML alias")
      }
      self.insert(node, 0, path)
    }
    StreamStart | StreamEnd => ()
  }
}

///|
fn load_ksy_yaml(source : String) -> Array[@yaml.Yaml] raise SchemaError {
  let loader : KsyYamlLoader = {
    frames: [],
    anchors: Map([]),
    documents: [],
    root: None,
    error: None,
  }
  @yaml.Parser::new(source[:]).load(loader, true) catch {
    @yaml.YamlError(mark~, info~) => invalid("YAML line \{mark.line + 1}", info)
  }
  if loader.error is Some(error) {
    raise error
  }
  loader.documents
}
