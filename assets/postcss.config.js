const path = require('path')

module.exports = (ctx) => {
  return {
    plugins: [
      require('postcss-import')({
        path: [
          path.join(__dirname, 'assets/css'),
          path.join(__dirname, 'assets')
        ]
      }),
      require('tailwindcss'),
      require('postcss-url'),
      require('postcss-preset-env'),
      require('postcss-nested')
    ]
  }
}
