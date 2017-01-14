module.exports = {
  parser: 'babel-eslint',
  extends: ['./../.eslintrc.js'],
  globals: {
    assert: true,
    sinon: true
  },
  env: {
    mocha: true
  }
};
