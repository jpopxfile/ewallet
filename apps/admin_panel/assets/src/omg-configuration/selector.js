export const selectConfigurationById = state => configurationId => {
  return state.configurations[configurationId] || {}
}

export const selectConfigurationsCachedQuery = state => cacheKey => {
  return _.chain(state.cacheQueries[cacheKey])
    .get('ids', [])
    .map(configurationId => {
      return selectConfigurationById(state)(configurationId)
    })
    .keyBy('key')
    .value()
}

export const selectConfigurationsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
