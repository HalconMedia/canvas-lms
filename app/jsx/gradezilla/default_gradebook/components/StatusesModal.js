/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react';
import ReactDOM from 'react-dom';
import { func, shape, string } from 'prop-types';
import update from 'react-addons-update';
import I18n from 'i18n!gradebook';
import Button from 'instructure-ui/lib/components/Button';
import Modal, { ModalBody, ModalFooter, ModalHeader } from 'instructure-ui/lib/components/Modal';
import Heading from 'instructure-ui/lib/components/Heading';
import Typography from 'instructure-ui/lib/components/Typography';
import { statuses } from 'jsx/gradezilla/default_gradebook/constants/statuses';
import StatusColorListItem from 'jsx/gradezilla/default_gradebook/components/StatusColorListItem';

class StatusesModal extends React.Component {
  static propTypes = {
    onClose: func.isRequired,
    colors: shape({
      late: string.isRequired,
      missing: string.isRequired,
      resubmitted: string.isRequired,
      dropped: string.isRequired,
      excused: string.isRequired
    }).isRequired,
    afterUpdateStatusColors: func.isRequired,
  };

  constructor (props) {
    super(props);

    this.colorPickerButtons = {};
    this.colorPickerContents = {};
    this.state = { isOpen: false, colors: props.colors };
  }

  updateStatusColors = status =>
    (color, successFn, failureFn) => {
      this.setState(
        prevState => update(prevState, { colors: { $merge: { [status]: color } } }),
        () => {
          const successFnAndClosePopover = () => {
            successFn();
            this.setState({ openPopover: null });
          };
          this.props.afterUpdateStatusColors(this.state.colors, successFnAndClosePopover, failureFn);
        }
      );
    }

  isPopoverShown (status) {
    return this.state.openPopover === status;
  }

  handleOnToggle = status =>
    (toggle) => {
      if (toggle) {
        this.setState({ openPopover: status });
      } else {
        this.setState({ openPopover: null });
      }
    }

  handleColorPickerAfterClose = status =>
    () => {
      this.setState({ openPopover: null }, () => {
        // eslint-disable-next-line react/no-find-dom-node
        ReactDOM.findDOMNode(this.colorPickerButtons[status]).focus();
      });
    }

  bindColorPickerButton = status =>
    (button) => {
      this.colorPickerButtons[status] = button;
    }

  bindColorPickerContent = status =>
    (content) => {
      this.colorPickerContents[status] = content;
    }


  bindDoneButton = (button) => { this.doneButton = button; };
  bindCloseButton = (button) => { this.closeButton = button; };
  bindContentRef = (content) => { this.modalContentRef = content; };

  open = () => {
    this.setState({ isOpen: true });
  }

  close = () => {
    this.setState({ isOpen: false });
  }

  renderListItems () {
    return statuses.map(status =>
      <StatusColorListItem
        key={status}
        status={status}
        color={this.state.colors[status]}
        isColorPickerShown={this.isPopoverShown(status)}
        colorPickerOnToggle={this.handleOnToggle(status)}
        colorPickerButtonRef={this.bindColorPickerButton(status)}
        colorPickerContentRef={this.bindColorPickerContent(status)}
        colorPickerAfterClose={this.handleColorPickerAfterClose(status)}
        afterSetColor={this.updateStatusColors(status)}
      />
    );
  }

  render () {
    const {
      state: { isOpen },
      props: { onClose },
      close,
      bindCloseButton,
      bindDoneButton,
      bindContentRef
    } = this;

    return (
      <Modal
        isOpen={isOpen}
        label={I18n.t('Statuses')}
        closeButtonLabel={I18n.t('Close')}
        closeButtonRef={bindCloseButton}
        onRequestClose={close}
        onExited={onClose}
        contentRef={bindContentRef}
      >
        <ModalHeader>
          <Heading level="h3">{I18n.t('Statuses')}</Heading>
        </ModalHeader>

        <ModalBody>
          <ul className="Gradebook__StatusModalList">
            <Typography>
              {this.renderListItems()}
            </Typography>
          </ul>
        </ModalBody>

        <ModalFooter>
          <Button
            ref={bindDoneButton}
            variant="primary"
            onClick={close}
          >
            {I18n.t('Done')}
          </Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default StatusesModal;
