class CustomFieldFormat extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      format: props.field.format,
      options: props.options
    }
    this.handleSelectFormat = this.handleSelectFormat.bind(this)
    this.handleAddOption = this.handleAddOption.bind(this)
    this.handleReorderOption = this.handleReorderOption.bind(this)
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
        <Reorder
          itemKey='id'
          lock='horizontal'
          list={this.state.options.filter((o) => !o._destroy)}
          template={Option}
          callback={this.handleReorderOption}
        />
        {this.renderNewOptionButton()}
      </div>
    )
  }

  renderNewOptionButton() {
    return (
      <div className="pull-right">
        <span className="btn btn-info" onClick={this.handleAddOption}>{this.props.new_option_label}</span>
      </div>
    )
  }

  handleSelectFormat(e) {
    const { value } = e.target
    this.setState({ format: value })
  }

  handleAddOption() {
    newOptions = [].concat(this.state.options, [{ id: 'new' + Math.random(), label: '' }])
    this.setState({ options: newOptions })
  }

  handleReorderOption(_, _, _, _, options) {
    this.setState({
      options
    })
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

class Option extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      deleted: false
    }
    this.handleDelete = this.handleDelete.bind(this)
  }

  render() {
    if (this.state.deleted) return this.renderDeleted()
    return (
      <div className="form-group">
        <div className="input-group">
          <span className="input-group-btn">
            <button
              type="button"
              className="btn btn-default"
            >
              <i className="fa fa-bars"/>
            </button>
          </span>
          <input
            type="hidden"
            name="custom_field[custom_field_options_attributes][][id]"
            value={this.props.item.id}
          />
          <input
            type="text"
            name="custom_field[custom_field_options_attributes][][label]"
            className="form-control"
            defaultValue={this.props.item.label}
          />
          <span className="input-group-btn">
            <button
              type="button"
              className="btn btn-delete"
              onClick={this.handleDelete}
            >
              <i className="fa fa-trash-o"/>
            </button>
          </span>
        </div>
      </div>
    )
  }

  renderDeleted() {
    return (
      <div>
        <input
          type="hidden"
          name="custom_field[custom_field_options_attributes][][id]"
          value={this.props.item.id}
        />
        <input
          type="hidden"
          name="custom_field[custom_field_options_attributes][][_destroy]"
          value={true}
        />
      </div>
    )
  }

  handleDelete() {
    this.setState({
      deleted: true
    })
  }
}

window.CustomFieldFormat = CustomFieldFormat
