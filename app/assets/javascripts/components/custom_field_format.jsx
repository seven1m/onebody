class CustomFieldFormat extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      format: props.field.format
    }
    this.handleSelectFormat = this.handleSelectFormat.bind(this)
  }

  render() {
    return (
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
    )
  }

  handleSelectFormat(e) {
    const { value } = e.target
    this.setState({ format: value })
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
