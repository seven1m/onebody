class CustomFieldFormat extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      format: props.field.format,
      options: props.options
    }
    this.handleSelectFormat = this.handleSelectFormat.bind(this)
    this.handleAddOption = this.handleAddOption.bind(this)
  }

  render() {
    return (
      <div>
        <div className="form-group">
          <label htmlFor="custom_field_format">{this.props.format_label}</label>
          <select
            className="form-control"
            id="custom_field_format"
            name="custom_field[format]"
            value={this.state.format}
            onChange={this.handleSelectFormat}
          >
            {this.props.format_options.map(([name, value]) => {
              return <option key={value} value={value}>{name}</option>
            })}
          </select>
        </div>
        {this.renderOptions()}
      </div>
    )
  }

  renderOptions() {
    if (this.state.format != 'select') return;
    return (
      <div>
        <label>{this.props.options_label}</label>
        {this.state.options.length == 0 ? <div><em>none</em></div> : null}
        {this.state.options.filter((o) => o._destroy).map((option) => (
          <div key={option.id}>
            <input
              type="hidden"
              name="custom_field[custom_field_options_attributes][][id]"
              value={option.id}
            />
            <input
              type="hidden"
              name="custom_field[custom_field_options_attributes][][_destroy]"
              value={true}
            />
          </div>
        ))}
        {this.state.options.filter((o) => !o._destroy).map((option) => (
          <div className="form-group" key={option.id || option.fakeId}>
            <div className="input-group">
              <input
                type="hidden"
                name="custom_field[custom_field_options_attributes][][id]"
                value={option.id}
              />
              <input
                type="text"
                name="custom_field[custom_field_options_attributes][][label]"
                className="form-control"
                value={option.label}
                onChange={this.handleChangeOption.bind(this, option)}
              />
              <span className="input-group-btn">
                <button
                  type="button"
                  className="btn btn-delete"
                  onClick={this.handleDeleteOption.bind(this, option)}
                >
                  <i className="fa fa-trash-o"/>
                </button>
              </span>
            </div>
          </div>
        ))}
        {this.renderNewOptionButton()}
      </div>
    )
  }

  renderNewOptionButton() {
    return (
      <div>
        <span className="btn btn-info" onClick={this.handleAddOption}>New</span>
      </div>
    )
  }

  handleSelectFormat(e) {
    const { value } = e.target
    this.setState({ format: value })
  }

  handleAddOption() {
    newOptions = [].concat(this.state.options, [{ label: '', fakeId: Math.random() }])
    this.setState({ options: newOptions })
  }

  handleChangeOption({ id, fakeId }, e) {
    newOptions = this.state.options.map((option) => {
      if ((option.id && option.id == id) || (option.fakeId && option.fakeId == fakeId)) {
        return { id: option.id, fakeId: option.fakeId, label: e.target.value }
      } else {
        return option
      }
    })
    this.setState({ options: newOptions })
  }

  handleDeleteOption({ id, fakeId }, e) {
    newOptions = this.state.options.map((option) => {
      if (option.id && option.id == id) {
        return { id: option.id, _destroy: true }
      } else if (option.fakeId && option.fakeId == fakeId) {
        return null
      } else {
        return option
      }
    }).filter((o) => o)
    this.setState({ options: newOptions })
  }
}

CustomFieldFormat.propTypes = {
  format_label: React.PropTypes.string.isRequired,
  format_options: React.PropTypes.arrayOf(
    React.PropTypes.arrayOf(
      React.PropTypes.string.isRequired,
      React.PropTypes.string.isRequired
    )
  ).isRequired,
  field: React.PropTypes.shape({
    format: React.PropTypes.string
  })
}

window.CustomFieldFormat = CustomFieldFormat
