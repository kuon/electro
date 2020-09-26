module.exports = {
  theme: {
    extend: {
      screens: {
        print: { raw: 'print' }
      },
      spacing: {
        128: '32rem',
        256: '64rem'
      },
      borderWidth: {
        12: '12px'
      }
    }
  },
  variants: {
    backgroundColor: ['responsive', 'hover', 'focus', 'disabled'],
    cursor: ['responsive', 'hover', 'focus', 'disabled'],
  }
}
