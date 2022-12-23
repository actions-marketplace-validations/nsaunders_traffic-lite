{ name = "my-project"
, dependencies =
  [ "aff"
  , "affjax"
  , "affjax-node"
  , "argonaut"
  , "arrays"
  , "console"
  , "control"
  , "dotenv"
  , "effect"
  , "either"
  , "exceptions"
  , "foldable-traversable"
  , "github-actions-toolkit"
  , "maybe"
  , "media-types"
  , "mmorph"
  , "node-buffer"
  , "node-fs"
  , "node-fs-aff"
  , "node-path"
  , "ordered-collections"
  , "prelude"
  , "transformers"
  , "tuples"
  , "typelevel-prelude"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
