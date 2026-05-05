#let required-params = (
  field-1: (
    type: "enum",
    default: (
      simple: (
        station-names: "阿鲁科尔沁旗;齐齐哈尔",
        station-pinyin: "ALUKEERQINQI;QIQIHAER",
      ),
    ),
    variations: (
      simple: (
        station-names: (
          type: "string",
          default: "阿鲁科尔沁旗;齐齐哈尔",
        ),
        station-pinyin: (
          type: "string",
          default: "ALUKEERQINQI;QIQIHAER",
        ),
      ),
      complex: (
        station-name-1: (
          type: "string",
          default: "红魔馆",
        ),
        station-pinyin-1: (
          type: "string",
          default: "HONG MO GUAN",
        ),
        station-name-2: (
          type: "string",
          default: "嬴异人",
        ),
        station-pinyin-2: (
          type: "string",
          default: "YING YI REN",
        ),
        class: (
          type: "string",
          default: "高速",
        ),
        trips-top: (
          type: "string",
          default: "G1234",
        ),
        trips-bottom: (
          type: "string",
          default: "G1235",
        ),
      ),
    ),
  ),
  field-2: (
    type: "enum",
    default: (
      complex: (
        station-name-1: "温州;永嘉",
        station-pinyin-1: "WEN ZHOU;YONG JIA",
        station-name-2: "都灵;米兰",
        station-pinyin-2: "TURIN;MILAN",
        class: "高速",
        trips-top: "G1234",
        trips-bottom: "G1235",
      ),
    ),
    variations: (
      simple: (
        station-names: (
          type: "string",
          default: "太平洋中央",
        ),
        station-pinyin: (
          type: "string",
          default: "PACIFIC CENTRAL",
        ),
      ),
      complex: (
        station-name-1: (
          type: "string",
          default: "温州;永嘉",
        ),
        station-pinyin-1: (
          type: "string",
          default: "WEN ZHOU;YONG JIA",
        ),
        station-name-2: (
          type: "string",
          default: "都灵;米兰",
        ),
        station-pinyin-2: (
          type: "string",
          default: "TURIN;MILAN",
        ),
        class: (
          type: "string",
          default: "高速",
        ),
        trips-top: (
          type: "string",
          default: "G1234",
        ),
        trips-bottom: (
          type: "string",
          default: "G1235",
        ),
      ),
    ),
  ),
  class: (
    type: "string",
    default: "动检",
  ),
  trips: (
    type: "string",
    default: "DJ1145;1919/20;6767;6969",
  ),
  color: (
    type: "string",
    default: "rgb(\"#DBB44B\")",
  ),
  logo-colors: (
    type: "enum",
    // default: (default: none),
    default: (default: none),
    variations: (
      default: none,
      simple: (
        background: (
          type: "string",
          default: "#000000",
        ),
        foreground: (
          type: "string",
          default: "#FFF954",
        ),
      ),
    ),
  ),
)

#metadata((
  fonts: ("Noto Sans CJK SC", "Noto Serif SC"),
  authors: (
    (name: "Jeremy Gao", ref: "https://paiagram.com"),
  ),
  params: required-params,
  published: "2026-05-03",
)) <template_data>


#let insert-path(dict, path, value) = {
  let key = path.at(0)
  if path.len() == 1 {
    dict.insert(key, value)
  } else {
    let rest = path.slice(1)
    let sub-dict = if key in dict and dict.at(key) != none {
      dict.at(key)
    } else {
      (:)
    }
    if type(sub-dict) != dictionary {
      panic("Key collision: '" + key + "' is a value (" + str(sub-dict) + "), cannot become a branch.")
    }
    dict.insert(key, insert-path(sub-dict, rest, value))
  }
  return dict
}

#let params = {
  let res = sys.inputs.at("params", default: none)
  if res == none {
    required-params.pairs().map(((k, v)) => (k, v.default)).to-dict()
  } else {
    let new_tree = (:)
    for (key, val) in json(bytes(res)) {
      let hierarchy = key.split("::")
      new_tree = insert-path(new_tree, hierarchy, val)
    }
    new_tree
  }
}

#set page(
  fill: white,
  height: auto,
  width: auto,
  margin: 0cm,
)

#set text(lang: "zh")
#show text.where(lang: "zh"): set text(bottom-edge: "descender", baseline: .2cm)
#let serif-text = text.with(font: "Noto Serif SC")
#let sans-text = text.with(font: "Noto Sans CJK SC")

#let format-text(
  station-names,
  text-fn: serif-text.with(size: 2.8cm, weight: "black"),
  insert-space: true,
  vertical-compress: true,
  max-line-hight: 999cm,
) = context {
  let stations = station-names.split(";")
  grid(
    rows: (1fr,) * stations.len(),
    ..stations.map(it => layout(size => {
      let text-fn = if vertical-compress { text-fn } else {
        text-fn.with(size: calc.min(size.height, max-line-hight))
      }
      let u = measure(text-fn(it))
      scale(
        reflow: true,
        x: calc.min(100%, size.width / u.width * 100%),
        y: if vertical-compress { 100% / stations.len() } else { 100% },
        if insert-space {
          text-fn(it.clusters().intersperse(h(1fr)).join())
        } else {
          text-fn(it)
        },
      )
    }))
  )
}

#let station-text(s) = context {
  grid(
    columns: (1fr,),
    rows: (1fr, 1.5cm, 4.4mm),
    {
      if s.at("simple", default: none) == none {
        grid(
          rows: 1fr,
          columns: (1fr, auto, 1fr),
          place(center + bottom, dy: -.4cm, box(height: 3cm, format-text(s.complex.station-name-1))),
          grid.cell(inset: .7cm)[
            #align(
              center + horizon,
              move(dy: .5cm, grid(
                rows: 2,
                inset: .2cm,
                stroke: (x, y) => if y == 0 { (bottom: 3pt) } else { none },
                sans-text(lang: "en", size: .5cm, s.complex.trips-top),
                sans-text(lang: "en", size: .5cm, s.complex.trips-bottom),
              )),
            )
            #place(center + top, dy: -.4cm, scale(reflow: true, y: 80%, box(width: 999em, sans-text(
              size: 0.8cm,
              tracking: .7cm,
              s.complex.class,
            ))))
          ],
          place(center + bottom, dy: -.4cm, box(height: 3cm, format-text(s.complex.station-name-2))),
        )
      } else {
        place(center + bottom, dy: -.4cm, box(height: 3cm, width: 9cm, format-text(s.simple.station-names)))
      }
    },
    grid.cell(align: center + horizon, fill: eval(params.color), inset: .1cm, {
      let format-fn = format-text.with(
        text-fn: serif-text.with(
          weight: "black",
          size: 1cm,
          fill: white,
          lang: "en",
        ),
        insert-space: false,
        vertical-compress: false,
        max-line-hight: 1cm,
      )
      if s.at("simple", default: none) == none {
        grid(
          columns: (auto, 3cm, auto),
          grid.cell(align: left, format-fn(s.complex.station-pinyin-1)),
          [],
          grid.cell(align: right, format-fn(s.complex.station-pinyin-2)),
        )
      } else {
        format-fn(s.simple.station-pinyin)
      }
    }),
    [],
  )
}

#let has-complex = (params.field-1.at("simple", default: none), params.field-2.at("simple", default: none)).any(it => (
  it == none
))
#let grid-width = if has-complex { 13cm } else { 11.5cm }

#box(inset: .5cm, grid(
  columns: (
    grid-width,
    7cm,
    grid-width,
  ),
  rows: (6cm,),
  station-text(params.field-1),
  {
    place(center + top, dy: .3cm, scale(y: 80%, sans-text(
      size: 1.1cm,
      tracking: 3.8cm,
      params.class,
    )))
    place(center + top, dy: .5cm, rect(stroke: none, width: 4cm, inset: 0cm, {
      let svg-str = read("logo.svg")
      if params.logo-colors.at("simple", default: none) != none {
        svg-str = svg-str.replace("#293965", params.logo-colors.simple.background)
        svg-str = svg-str.replace("#f68323", params.logo-colors.simple.foreground)
      }
      image(bytes(svg-str), format: "svg")
    }))
    let trip-numbers = params.trips.trim().split(";")
    place(center + top, dy: 4.7cm, box(
      width: 6cm,
      {
        set align(center + top)
        set par(leading: 2mm)
        trip-numbers
          .map(it => box(scale(reflow: true, y: 80%, sans-text(lang: "en", size: .7cm, it))))
          .intersperse(h(.8em, weak: true))
          .join()
      },
    ))
  },
  station-text(params.field-2),
))
