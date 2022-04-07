module.exports = async (str) => {
  str = str.replace(/`/gi, '\\`');
  return `export default \`${str}\`;`;
};
