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
        {this.state.options.map((option) => (
          <div className="form-group" key={option.id || option.fakeId}>
            <div className="input-group">
              <input
                name="custom_field[custom_field_options_attributes][][label]"
                className="form-control"
                value={option.label}
              />
              <span className="input-group-btn">
                <button type="button" className="btn btn-delete">
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
