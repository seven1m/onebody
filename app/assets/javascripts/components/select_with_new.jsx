class SelectWithNew extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      value: props.value,
      custom: false
    }
  }

  render() {
    if (this.state.custom) {
      return this.renderInput()
    } else {
      return this.renderSelect()
    }
  }

  renderInput() {
    return (
      <div className="input-group">
        <input
          id={this.id}
          name={this.props.name}
          value={this.state.value}
          onChange={this.handleChangeInput.bind(this)}
          className={`${this.props.className} ${this.changedClass} form-control`}
          autoFocus={true}
        />
        <span className="input-group-btn">
          <span
            className="btn btn-danger"
            onClick={this.handleCancelInput.bind(this)}
          >
            <i className="fa fa-times-circle"/>
          </span>
        </span>
      </div>
    )
  }

  renderSelect() {
    return (
      <select
        id={this.id}
        className={`${this.props.className} ${this.changedClass}`}
        name={this.props.name}
        value={this.state.value || ''}
        onChange={this.handleChangeSelect.bind(this)}
      >
        {this.props.includeBlank ? <option/> : null}
        {this.props.options.map(([label, value]) => (
          <option key={value} value={value}>{label}</option>
        ))}
      </select>
    )
  }

  handleChangeInput(e) {
    const { value } = e.target
    this.setState({ value })
  }

  handleChangeSelect(e) {
    let { value } = e.target
    const custom = value === '!'
    if (custom) value = ''
    this.setState({ value, custom })
  }

  handleCancelInput() {
    const { value } = this.props
    this.setState({ value, custom: false })
  }

  get changedClass() {
    if (this.state.value !== this.props.value) return 'changed'
  }

  get id() {
    return this.props.name.replace(/\[/g, '_').replace(/\]/g, '')
  }
}

SelectWithNew.defaultProps = {
  className: ''
}

SelectWithNew.propTypes = {
  name: React.PropTypes.string.isRequired,
  value: React.PropTypes.string,
  options: React.PropTypes.arrayOf(
    React.PropTypes.arrayOf(
      React.PropTypes.string.isRequired,
      React.PropTypes.number.isRequired
    )
  ).isRequired,
  className: React.PropTypes.string,
  includeBlank: React.PropTypes.bool
}

window.SelectWithNew = SelectWithNew
